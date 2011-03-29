class KennyPatch
  attr_accessor :uuid, :fname, :patch_dir

  def initialize(repo, fname, uuid)
    @repo = repo
    @fname = fname
    @uuid = uuid

    # create patch directory
    @patch_dir = @repo.commits_path + File::Separator + @uuid

    # create parent directory
    @parent_dir = @patch_dir + File::Separator + @repo.get_current

    # make an empty children file
    File.open(@patch_dir + File::Separator + 'children','w') {|f| }
    
    # check existence
    if fname.nil? && File.exist?(@patch_dir) && File.directory?(@patch_dir)
      @fname = File.read(@patch_dir + File::Separator + "file").strip
    end
  end
  
  def process_fname(name)
    # Do nothing - no common behavior
  end
  
  def type
    "unknown"
  end

  def create
    puts 'Creating ' + @patch_dir + '.'
    Dir.mkdir(@patch_dir)
    
    puts "Recording type #{self.type}."
    File.open(@patch_dir + File::Separator + "type", "w") {|f| f << self.type}
    
    puts "Recording file name #{@fname}."
    File.open(@patch_dir + File::Separator + "file", "w") {|f| f << @fname}

    puts 'Creating ' + @parent_dir + '.'
    Dir.mkdir(@parent_dir)

    # add new patch as a child to the current patch
    File.open(@repo.commits_path + File::Separator + @repo.get_current + File::Separator + 'children', 'a') << @uuid + "\n"

    # return uuid
    @uuid
  end

  def apply
    # if patch is not a child of the current version, then reject
    unless File.exist?(@parent_dir)
      raise 'Patch ' + @uuid + ' is not a child of the current patch ' + @repo.get_current + '.'
    end
  end

  def unapply
    # if patch to be unapplied back to does not exist, then reject
    unless File.exist?(@patch_dir)
      raise 'Patch ' + @uuid + ' does not exist.'
    end
  end
  
  def parents
    parent_list = []
    Dir.new(@patch_dir).each do |entry|
      if File.directory?(@patch_dir + File::Separator + entry) && entry != "." && entry != ".."
        patch = @repo.patch_for_uuid(entry)
        parent_list.push(patch)
      end
    end
    return parent_list
  end

  def children
    children_list = []
    File.open(@patch_dir + File::Separator + 'children').each { |line| 
      children_list.push(@repo.patch_for_uuid(line.strip)) }
    return children_list
  end
  
  def find_ancestry(target_fname)
    # Find one possible path from this patch to the given file's creation
    ancestry = self.parents[0].find_ancestry(target_fname)
    if target_fname == @fname
      ancestry.push(self)
    end
    return ancestry
  end
end
