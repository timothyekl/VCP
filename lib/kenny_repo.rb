['kenny_patch', 'root_patch', 'add_patch', 'modify_patch'].each {|n| require File.dirname(__FILE__) + File::Separator + "#{n}.rb"}

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

  def info
    s = "Repository at #{@path}\n"
    s += "Current commit: #{self.get_current}"

    return s
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
    #Dir.mkdir(self.commits_path + File::Separator + "0") # use 0 to represent root
    #File.open(self.commits_path + File::Separator + "0" + File::Separator + "type", "w") {|f| f << "root"}
    RootPatch.new(self).create
    File.open(self.current_path, "w") {|f| f << '0' }
    return true
  end

  def make_add_patch(fname)
    uuid = AddPatch.new(self, fname, get_uuid).create
    File.open(current_path, 'w') {|f| f << uuid }
  end

  # uuid is the uuid of the patch to apply
  def apply_add_patch(uuid)
    AddPatch.new(self, nil, uuid).apply
    File.open(current_path, 'w') {|f| f << uuid }
  end

  # uuid is the uuid of the patch to unapply back to
  # TODO: refactor uuid to be an argument of create/apply/unapply instead of initialize
  def unapply_add_patch(uuid)
    AddPatch.new(self, nil, uuid).unapply
    File.open(current_path, 'w') {|f| f << uuid }
  end

  def get_uuid
    `uuid`.strip
  end

  def get_current
    File.read(self.current_path).strip
  end
  
  def patch_for_uuid(uuid)
    patch = nil
    requested_path = self.commits_path + File::Separator + uuid
    if File.exist?(requested_path) && File.directory?(requested_path)
      type = File.read(requested_path + File::Separator + "type")
      case type
      when "root"
        patch = RootPatch.new(self)
      when "add"
        patch = AddPatch.new(self, nil, uuid)
      when "modify"
        patch = ModifyPatch.new(self, nil, uuid)
      end
    end
    return patch
  end
end
