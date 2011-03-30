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

    if File.exist?(self.metadata_path) && File.directory?(self.metadata_path)
      if File.exist?(self.tmp_path)
        #Dir.rmdir(self.tmp_path)
        FileUtils::remove_dir(self.tmp_path, force=true)
      end
      Dir.mkdir(self.tmp_path)
    end
  end

  def info
    s = "Repository at #{@path}\n"
    s += "Current commit: #{self.get_current}\n"
    p = patch_for_uuid(self.get_current).parents
    if p.size > 0
      s += "Parents of current commit:\n"
      p.each { |parent| s += "\t#{parent.uuid}\n" }
    else
      s += "No parents of this commit\n"
    end
    c = patch_for_uuid(self.get_current).children
    if c.size > 0
      s += "Children of current commit:\n"
      c.each { |child| s += "\t#{child.uuid}\n" }
    else
      s += "No children of this commit\n"
    end

    return s
  end

  def metadata_path
    @path + File::Separator + ".kenny"
  end

  def tmp_path
    self.metadata_path + File::Separator + "tmp"
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
    Dir.mkdir(self.tmp_path)
    #Dir.mkdir(self.commits_path + File::Separator + "0") # use 0 to represent root
    #File.open(self.commits_path + File::Separator + "0" + File::Separator + "type", "w") {|f| f << "root"}
    RootPatch.new(self).create
    File.open(self.current_path, "w") {|f| f << '0' }
    return true
  end

  def apply_patch(uuid)
    type = self.patch_for_uuid(uuid).type
    case type
    when "root"
      raise "Cannot apply root patch"
    when "add"
      self.apply_add_patch(uuid)
    when "modify"
      self.apply_modify_patch(uuid)
    else
      raise "Patch type #{type} unimplemented for apply action"
    end
  end

  def unapply_patch(uuid)
    type = self.patch_for_uuid(uuid).type
    case type
    when "root"
      raise "Cannot unapply root patch"
    when "add"
      self.unapply_add_patch(uuid)
    when "modify"
      self.unapply_modify_patch(uuid)
    else
      raise "Patch type #{type} unimplemented for unapply action"
    end
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

  def make_modify_patch(fname)
    uuid = ModifyPatch.new(self, fname, get_uuid).create
    File.open(current_path, 'w') {|f| f << uuid}
  end

  def apply_modify_patch(uuid)
    ModifyPatch.new(self, nil, uuid).apply
    File.open(current_path, 'w') {|f| f << uuid}
  end

  # uuid is the uuid of the patch to unapply back to
  # TODO: refactor uuid to be an argument of create/apply/unapply instead of initialize
  def unapply_add_patch(uuid)
    AddPatch.new(self, nil, uuid).unapply
    File.open(current_path, 'w') {|f| f << uuid }
  end

  def unapply_modify_patch(uuid)
    new_uuid = ModifyPatch.new(self, nil, uuid).unapply
    File.open(current_path, 'w') {|f| f << new_uuid}
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
