require 'fileutils'

require File.join(File.dirname(__FILE__), '..', 'kenny_repo.rb')

ORIG_STDOUT = $stdout
$stdout = File.new('/dev/null', 'w')

# InputFaker from: https://gist.github.com/194554
class InputFaker
  def initialize(strings)
      @strings = strings
  end

  def gets
    next_string = @strings.shift
    next_string
  end
                  
  def self.with_fake_input(strings)
    $stdin = new(strings)
    yield
  ensure
    $stdin = STDIN
  end
end
                  
describe 'KennyRepo' do
  REPO_PATH = File.expand_path(File.join('.', 'sandbox'))

  describe 'creation' do
    it 'should create a repo for an existing directory' do
      FileUtils::rm_rf [REPO_PATH]
      FileUtils::mkdir REPO_PATH

      repo = KennyRepo.new(REPO_PATH)
      repo.should_not == nil
      repo.class.should == KennyRepo

      FileUtils::rm_rf [REPO_PATH]
    end

    it 'should die on a nonexistent directory' do
      FileUtils::rm_rf [REPO_PATH]

      lambda { repo = KennyRepo.new(REPO_PATH) }.should raise_error(RuntimeError)
    end

    it 'should die on a regular file' do
      FileUtils::touch [REPO_PATH]

      lambda { repo = KennyRepo.new(REPO_PATH) }.should raise_error(RuntimeError)
    end

    it 'should remove existing .kenny/tmp directories' do
      FileUtils::rm_rf [REPO_PATH]
      FileUtils::mkdir REPO_PATH
      FileUtils::mkdir File.join(REPO_PATH, '.kenny')
      FileUtils::mkdir File.join(REPO_PATH, '.kenny', 'tmp')
      FileUtils::touch File.join(REPO_PATH, '.kenny', 'tmp', 'file')

      repo = KennyRepo.new(REPO_PATH)

      File.exist?(File.join(REPO_PATH, '.kenny', 'tmp', 'file')).should == false
    end
  end

  describe 'initialization' do
    before(:each) do
      FileUtils::rm_rf [REPO_PATH]
      FileUtils::mkdir REPO_PATH
      @repo = KennyRepo.new(REPO_PATH)
    end

    it 'should create a .kenny directory' do
      @repo.init_repo
      
      File.exist?(File.join(REPO_PATH, '.kenny')).should == true
      File.directory?(File.join(REPO_PATH, '.kenny')).should == true
    end

    it 'should pick up on existing .kenny directories' do
      FileUtils::mkdir File.join(REPO_PATH, '.kenny')

      lambda { @repo.init_repo }.should raise_error(RuntimeError)
    end

    it 'should have a .kenny/commits directory' do
      @repo.init_repo
      
      File.exist?(File.join(REPO_PATH, '.kenny', 'commits')).should == true
      File.directory?(File.join(REPO_PATH, '.kenny', 'commits')).should == true
    end

    it 'should have a .kenny/tmp directory' do
      @repo.init_repo
      
      File.exist?(File.join(REPO_PATH, '.kenny', 'tmp')).should == true
      File.directory?(File.join(REPO_PATH, '.kenny', 'tmp')).should == true
    end

    it 'should have a .kenny/current file' do
      @repo.init_repo
      
      File.exist?(File.join(REPO_PATH, '.kenny', 'current')).should == true
      File.file?(File.join(REPO_PATH, '.kenny', 'current')).should == true
    end

    it 'should have the current commit be 0' do
      @repo.init_repo

      File.exist?(File.join(REPO_PATH, '.kenny', 'commits', '0')).should == true
      File.directory?(File.join(REPO_PATH, '.kenny', 'commits', '0')).should == true

      File.read(File.join(REPO_PATH, '.kenny', 'current')).strip.should == "0"
      @repo.get_current.should == "0"
    end
    
    after(:each) do
      FileUtils::rm_rf [REPO_PATH]
    end
  end

  describe 'basic properties' do
    before(:each) do
      FileUtils::rm_rf [REPO_PATH]
      FileUtils::mkdir REPO_PATH
      @repo = KennyRepo.new(REPO_PATH)
      @repo.init_repo
    end

    it 'should have a valid metadata path' do
      @repo.metadata_path.should == File.expand_path(File.join(REPO_PATH, '.kenny'))
    end
    
    it 'should have a valid tmp path' do
      @repo.tmp_path.should == File.expand_path(File.join(REPO_PATH, '.kenny', 'tmp'))
    end
    
    it 'should have a valid commits path' do
      @repo.commits_path.should == File.expand_path(File.join(REPO_PATH, '.kenny', 'commits'))
    end
    
    it 'should have a valid current path' do
      @repo.current_path.should == File.expand_path(File.join(REPO_PATH, '.kenny', 'current'))
    end
    

    after(:each) do
      FileUtils::rm_rf [REPO_PATH]
    end
  end

  describe 'add patch' do
    before(:each) do
      FileUtils::rm_rf [REPO_PATH]
      FileUtils::mkdir REPO_PATH

      @repo = KennyRepo.new(REPO_PATH)
      @repo.init_repo

      @test_filename = "testfile.txt"
      FileUtils::touch File.join(REPO_PATH, @test_filename)
    end

    it 'should be creatable' do
      Dir.chdir(REPO_PATH)
      @repo.make_add_patch(@test_filename)

      uuid = @repo.get_current
      uuid.should_not == "0"
      
      File.exist?(File.join(REPO_PATH, '.kenny', 'commits', uuid.to_s)).should == true
      File.exist?(File.join(REPO_PATH, '.kenny', 'commits', uuid.to_s, '0')).should == true
      File.exist?(File.join(REPO_PATH, '.kenny', 'commits', uuid.to_s, '0', "#{@test_filename}.base")).should == true
      File.read(File.join(REPO_PATH, '.kenny', 'commits', uuid, '0', "#{@test_filename}.base")).strip.should == ""
    end

    it 'should be unapplyable' do
      Dir.chdir(REPO_PATH)
      @repo.make_add_patch(@test_filename)
      uuid = @repo.get_current

      @repo.unapply_patch(uuid)

      @repo.get_current.should == "0"
      File.exist?(File.join(REPO_PATH, @test_filename)).should == false
    end

    it 'should be applyable' do
      Dir.chdir(REPO_PATH)
      @repo.make_add_patch(@test_filename)
      uuid = @repo.get_current

      @repo.unapply_patch(uuid)
      @repo.apply_patch(uuid)

      @repo.get_current.should == uuid
      File.exist?(File.join(REPO_PATH, @test_filename)).should == true
    end

    it 'should be applyable and unapplyable in extended sequences' do
      Dir.chdir(REPO_PATH)
      @repo.make_add_patch(@test_filename)
      uuid1 = @repo.get_current

      alt_test_filename = "#{@test_filename.chomp('.txt')}-2.txt"
      FileUtils::touch File.join(REPO_PATH, alt_test_filename)
      @repo.make_add_patch(alt_test_filename)
      uuid2 = @repo.get_current

      @repo.unapply_patch(uuid2)
      @repo.unapply_patch(uuid1)

      File.exist?(File.join(REPO_PATH, @test_filename)).should == false
      File.exist?(File.join(REPO_PATH, alt_test_filename)).should == false
      @repo.get_current.should == "0"

      @repo.apply_patch(uuid1)
      @repo.apply_patch(uuid2)

      File.exist?(File.join(REPO_PATH, @test_filename)).should == true
      File.exist?(File.join(REPO_PATH, alt_test_filename)).should == true
      @repo.get_current.should == uuid2
    end

    after(:each) do
      FileUtils::rm_rf [REPO_PATH]
    end
  end

  describe 'modify patch' do
    before(:each) do
      FileUtils::rm_rf [REPO_PATH]
      FileUtils::mkdir REPO_PATH

      @repo = KennyRepo.new(REPO_PATH)
      @repo.init_repo

      @test_filename = "testfile.txt"
      FileUtils::touch File.join(REPO_PATH, @test_filename)

      Dir.chdir(REPO_PATH)

      @repo.make_add_patch(@test_filename)
      @add_uuid = @repo.get_current
    end

    it 'should be creatable' do
      test_string = "Test string"
      File.open(File.join(REPO_PATH, @test_filename), 'a') { |f| f << test_string }
      File.read(File.join(REPO_PATH, @test_filename)).strip.should == test_string

      @repo.make_modify_patch(@test_filename)
      modify_uuid = @repo.get_current
      modify_uuid.should_not == @add_uuid
      modify_uuid.should_not == "0"

      modify_patch = ModifyPatch.new(@repo, nil, modify_uuid)
      modify_patch.nil?.should == false
      modify_patch.parents.size.should == 1
      modify_patch.parents[0].uuid.should == @add_uuid

      add_patch = AddPatch.new(@repo, nil, @add_uuid)
      add_patch.nil?.should == false
      add_patch.children.size.should == 1
      add_patch.children[0].uuid.should == modify_uuid
    end

    it 'should be unapplyable' do
      test_string = "Test string"
      File.open(File.join(REPO_PATH, @test_filename), 'a') { |f| f << test_string }
      @repo.make_modify_patch(@test_filename)
      modify_uuid = @repo.get_current

      @repo.unapply_modify_patch(modify_uuid)

      @repo.get_current.should == @add_uuid
      File.read(File.join(REPO_PATH, @test_filename)).strip.should == ""
    end

    it 'should be applyable' do
      test_string = "Test string"
      File.open(File.join(REPO_PATH, @test_filename), 'a') { |f| f << test_string }
      @repo.make_modify_patch(@test_filename)
      modify_uuid = @repo.get_current

      @repo.unapply_modify_patch(modify_uuid)
      @repo.apply_modify_patch(modify_uuid)

      @repo.get_current.should == modify_uuid
      File.read(File.join(REPO_PATH, @test_filename)).strip.should == test_string
    end

    it 'should be chainable' do
      test_string = "Test string"
      File.open(File.join(REPO_PATH, @test_filename), 'a') { |f| f << test_string }
      @repo.make_modify_patch(@test_filename)
      modify_1_uuid = @repo.get_current

      File.open(File.join(REPO_PATH, @test_filename), 'a') { |f| f << test_string }
      @repo.make_modify_patch(@test_filename)
      modify_2_uuid = @repo.get_current

      modify_1_uuid.should_not == modify_2_uuid
      modify_1_uuid.should_not == "0"
      modify_2_uuid.should_not == "0"

      patch_1 = ModifyPatch.new(@repo, nil, modify_1_uuid)
      patch_2 = ModifyPatch.new(@repo, nil, modify_2_uuid)

      @repo.unapply_modify_patch(modify_2_uuid)
      @repo.get_current.should == modify_1_uuid
      
      @repo.unapply_modify_patch(modify_1_uuid)
      @repo.get_current.should == @add_uuid
      File.read(File.join(REPO_PATH, @test_filename)).strip.should == ""

      @repo.apply_modify_patch(modify_1_uuid)
      @repo.get_current.should == modify_1_uuid
      File.read(File.join(REPO_PATH, @test_filename)).strip.should == test_string

      @repo.apply_modify_patch(modify_2_uuid)
      @repo.get_current.should == modify_2_uuid
    end

    after(:each) do
      FileUtils::rm_rf [REPO_PATH]
    end
  end

  describe 'branching' do
    before(:each) do
      FileUtils::rm_rf [REPO_PATH]
      FileUtils::mkdir REPO_PATH

      @repo = KennyRepo.new(REPO_PATH)
      @repo.init_repo

      @test_filename = "testfile.txt"
      FileUtils::touch File.join(REPO_PATH, @test_filename)

      Dir.chdir(REPO_PATH)
      @repo.make_add_patch(@test_filename)
      @add_uuid = @repo.get_current
    end

    it 'should be doable' do
      InputFaker.with_fake_input(["y"]) do
        File.open(File.join(REPO_PATH, @test_filename), 'a') { |f| f << "Hello" } 
        @repo.make_modify_patch(@test_filename)
        hello_uuid = @repo.get_current

        @repo.unapply_modify_patch(hello_uuid)
        @repo.get_current.should == @add_uuid
        File.read(File.join(REPO_PATH, @test_filename)).strip.should == ""

        File.open(File.join(REPO_PATH, @test_filename), 'a') { |f| f << "Goodbye" }
        @repo.make_modify_patch(@test_filename)
        goodbye_uuid = @repo.get_current
        goodbye_uuid.should_not == hello_uuid

        @repo.unapply_modify_patch(goodbye_uuid)
        @repo.get_current.should == @add_uuid
        File.read(File.join(REPO_PATH, @test_filename)).strip.should == ""

        @repo.apply_modify_patch(hello_uuid)
        @repo.get_current.should == hello_uuid
        File.read(File.join(REPO_PATH, @test_filename)).strip.should == "Hello"
      end
    end

    after(:each) do
      FileUtils::rm_rf [REPO_PATH]
    end
  end
end
