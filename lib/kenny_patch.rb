class KennyPatch
  attr_accessor :uuid

  def initialize(repo, fname, uuid)
    @repo = repo
    @fname = fname
    @uuid = uuid

    # create patch directory
    @patch_dir = @repo.commits_path + File::Separator + @uuid

    # create parent directory
    @parent_dir = @patch_dir + File::Separator + @repo.get_current
  end

  def create
    puts 'Creating ' + @patch_dir + '.'
    Dir.mkdir(@patch_dir)

    puts 'Creating ' + @parent_dir + '.'
    Dir.mkdir(@parent_dir)

    # add new patch as a child to the current patch
    File.open(@repo.commits_path + File::Separator + @repo.get_current + File::Separator + 'children', 'a') << @uuid + '\n'

    # return uuid
    @uuid
  end

  def apply
  end

  def unapply
  end
end
