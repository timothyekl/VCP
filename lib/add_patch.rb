class AddPatch < KennyPatch
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

  def apply
    # if patch is not a child of the current version, then reject call
    puts @parent_dir
    unless File.exist?(@parent_dir)
      raise 'Cannot apply patch ' + @uuid + ' to repository with state ' + @repo.get_current + '.'
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
  end
end
