class AddPatch < KennyPatch
  def inspect
    return "Add patch #{@uuid}"
  end

  def create
    super()

    # if file isn't in the root directory of the repository, then mirror directory tree in repository metadata
    unless File.exist?(File.basename(@fname))
      FileUtils::mkdir(File.dirname(@parent_dir + File::Separator + @fname))
    end

    # create patch data
    FileUtils::cp(@fname, @parent_dir + File::Separator + @fname + '.base')

    @uuid
  end

  def type
    "add"
  end

  def process_fname(name)
    super(name)

    if name[-5,5] == ".base"
      return name[0..-6]
    else
      return name
    end
  end

  def apply
    # if patch is not a child of the current version, then reject
    unless File.exist?(@parent_dir)
      raise 'Patch ' + @uuid + ' is not a child of the current patch ' + @repo.get_current + '.'
    end

    # for each .base file, copy to repository
    Dir.glob(File.join(@parent_dir, "**", "*.base")) do |file|
      # determine file path relative to repository root
      relpath = Pathname.new(file).relative_path_from(Pathname.new(@parent_dir))

      # copy .base file to repository, chomping off '.base' extension
      FileUtils::cp(file, @repo.path + File::Separator + relpath.to_s.chomp('.base'))
    end
  end

  def unapply
    # if patch to be unapplied back to does not exist, then reject
    unless File.exist?(@patch_dir)
      raise 'Patch ' + @uuid + ' does not exist.'
    end

    # if patch is not a parent of the current version, then reject
    unless File.read(@patch_dir + File::Separator + 'children').include?(@repo.get_current)
      raise 'Patch ' + @uuid + ' is not a parent of the current patch ' + @repo.get_current + '.'
    end

    # for each .base file, attempt to remove from repository
    Dir.glob(File.join(@repo.commits_path, @repo.get_current, @uuid, "**", "*.base")) do |file|
      puts 'FILE: ' + file

      # determine file path relative to repository root
      relpath = Pathname.new(file).relative_path_from(Pathname.new(File.join(@repo.commits_path, @repo.get_current, @uuid)))
      puts 'RELPATH: ' + relpath.to_s

      puts(@repo.path + File::Separator + relpath.to_s.chomp('.base'))
      if File.read(Pathname.new(file).cleanpath.to_s) == File.read(@repo.path + File::Separator + relpath.to_s.chomp('.base'))
        puts 'DELETING!'
        File.delete(@repo.path + File::Separator + relpath.to_s.chomp('.base'))
      end
    end
  end
end
