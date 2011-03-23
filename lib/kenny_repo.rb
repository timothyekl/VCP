class KennyRepo
  attr_accessor :path

  def initialize(path)
    if !File.exist?(path)
      raise "Path doesn't exist."
    end

    if !File.directory?(path)
      raise "Path is not a directory."
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

  def init_repo
    # a .kenny directory already exists
    raise "Repository already initialized." if File.exist?(self.metadata_path)

    # no .kenny subdirectory - need to create everything
    dir = Dir.mkdir(self.metadata_path)
    Dir.mkdir(self.commits_path)
    Dir.mkdir(self.commits_path + File::Separator + "0") # use 0 to represent root
    File.open(self.current_path, "w") {|f| f << '0' }
    return true
  end

  def make_add_patch(fname)
    uuid = AddPatch.new(self, fname, get_uuid).create
    File.open(current_path, 'w') {|f| f << uuid }
  end

  def apply_add_patch(uuid)
    AddPatch.new(self, '.', uuid).apply
    File.open(current_path, 'w') {|f| f << uuid }
  end

  def get_uuid
    `uuid`.strip
  end

  def get_current
    File.read(self.current_path).strip
  end
end
