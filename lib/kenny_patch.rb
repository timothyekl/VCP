class KennyPatch
  attr_accessor :uuid

  def initialize(repo, fpath)
    @repo = repo
    @fpath = fpath
    @uuid = `uuid`
  end

  def create
    # create patch directory
    @patch_dir = @repo.commits_path + File::Separator + @uuid
    puts 'Creating ' + @patch_dir + '.'
    Dir.mkdir(@patch_dir)

    # create parent directory
    @parent_dir = @patch_dir + File::Separator + @repo.get_current
    puts 'Creating ' + @parent_dir + '.'
    Dir.mkdir(@parent_dir)

    # add new patch as a child to the current patch
    File.open(@repo.commits_path + File::Separator + @repo.get_current + File::Separator + 'children', 'a') << @uuid + '\n'

    @uuid
  end

  def apply
  end

  def unapply
  end
end
