class AddPatch < KennyPatch
  def create
    super()

    # create patch data
    FileUtils::cp(@fpath, @parent_dir + File::Separator + File::basename(@fpath) + '.base')

    @uuid
  end

  def apply
  end

  def unapply
  end
end
