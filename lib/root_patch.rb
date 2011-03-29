class RootPatch < KennyPatch
  def inspect
    return "Root patch"
  end
  
  def initialize(repo)
    @repo = repo
    @fname = ""
    @uuid = 0
    
    # create patch directory
    @patch_dir = @repo.commits_path + File::Separator + @uuid.to_s
  end
  
  def create
    puts 'Creating ' + @patch_dir + '.'
    Dir.mkdir(@patch_dir)
    
    puts "Recording type #{self.type}."
    File.open(@patch_dir + File::Separator + "type", "w") {|f| f << self.type}
    
    puts "Recording empty file name."
    File.open(@patch_dir + File::Separator + "file", "w") {|f| f << @fname}
    
    @uuid
  end
  
  def type
    "root"
  end
  
  def find_ancestry(target_fname)
    return []
  end
end