class KennyRepo
  attr_accessor :path

  def initialize(path)
    if !File.exist?(path)
      raise "Path doesn't exist"
    end

    if !File.directory?(path)
      raise "Path is not a directory"
    end

    @path = File.expand_path(path)
  end

  def metadata_path
    @path + File::Separator + ".kenny"
  end

  def commits_path
    self.metadata_path + File::Separator + "commits"
  end

  def current_path
    self.metadata_path + File::Separator + "current"
  end

  def make_repo
    if File.exist?(self.metadata_path)
      # Something called .kenny exists
      raise ".kenny already exists"
    else
      # No .kenny subdir - need to create everything
      dir = Dir.mkdir(self.metadata_path)
      Dir.mkdir(self.commits_path)
    end
    Dir.mkdir(self.commits_path + File::Separator + "0") # use 0 to represent root
    File.open(self.current_path, "w") { |file| file.puts "0" }
    return true
  end

  def make_add_patch(file_name)
    # get a new uuid
    uuid = self.get_uuid
    # make a new patch directory with that uuid
    patch_dir = self.commits_path + File::Separator + uuid
    Dir.mkdir(patch_dir)
    # make a subdirectory with the current patch uuid
    parent_dir = patch_dir + File::Separator + self.get_current
    Dir.mkdir(parent_dir)
    # in that subdirectory put the base contents of the file
    File.open(@path + File::Separator + file_name) do |src|
      File.open(parent_dir + File::Separator + file_name + ".base", "w") do |dest|
        src.each { |line| dest.puts line }
      end
    end
    # add a child to the current patch
    File.open(self.commits_path + File::Separator + self.get_current + File::Separator + "children","a") do |childs|
      childs.puts uuid
    end
    # update the current patch to the new patch
    File.open(self.current_path, "w") { |file| file.puts uuid }
  end

  def get_uuid
    uuid = %x[uuid]
    return uuid[0...uuid.size-1]
  end

  def get_current
    str = File.read(self.current_path)
    return str[0...str.size-1]
  end
end
