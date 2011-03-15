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
    return @path + File::Separator + ".kenny"
  end
  
  def commits_path
    return self.metadata_path + File::Separator + "commits"
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
    return true
  end
end