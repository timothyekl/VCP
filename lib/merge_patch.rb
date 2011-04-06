class MergePatch < KennyPatch

  def create(other_uuid)
    super()

    # To merge the current patch with patch X
    # 1. Find the most recent common ancestor Anc
    #   1.1 If head is an ancestor of X, abort
    #   1.2 If X is an ancestor of head, abort
    #   NB: just use the brute force comparison
    headChangeList = parents.first.find_ancestry(@fname)
    puts "Head change list #{headChangeList.map {|x| x.uuid + ', '}}"
    other = @repo.patch_for_uuid(other_uuid)
    puts "Other: #{other.uuid}"
    otherChangeList = other.find_ancestry(@fname)
    puts "Other change list #{otherChangeList.map {|x| x.uuid + ', '}}"
    if headChangeList.include?(other)
      raise "Cannot merge #{self.uuid} with its ancestor #{other.uuid}"
    end
    if otherChangeList.include?(self)
      raise "Cannot merge #{self.uuid} with its child #{other.uuid}"
    end
    mca = (headChangeList.select { |e| otherChangeList.include?(e) }).last
    puts "The most recent common ancestor is #{mca.uuid}"

    # 2. Generate the working set of X.
    #   2.1 Apply the inverse of the diffs from head to Anc
    #   2.2 Apply the diffs from Anc to X
    #   NB: do it to a copy and do it nondestructively
    backToMCA = headChangeList.reverse.take_while {|x| x != mca}
    puts "Patches back to MCA #{backToMCA.map {|x| x.uuid + ', '}}"
    mcaToOther = (otherChangeList.drop_while {|x| x != mca}).drop(1)
    puts "Patches from MCA to Other #{mcaToOther.map {|x| x.uuid + ', '}}"

    head_file = File.join(@repo.path, @fname)
    tmp_file = File.join(@repo.tmp_path, @fname)
    FileUtils.cp(head_file, tmp_file)
    backToMCA.each do |modification|
      mod_diff_path = Dir.glob(File.join(modification.patch_dir, "**", "#{@fname}.diff")).first
      puts "Undoing patch #{modification.uuid}"
      %x(patch -R #{tmp_file} #{mod_diff_path})
    end
    common_file = File.join(@repo.tmp_path, @fname + '.common')
    FileUtils.cp(tmp_file, common_file)
    mcaToOther.each do |modification|
      mod_diff_path = Dir.glob(File.join(modification.patch_dir, "**", "#{@fname}.diff")).first
      puts "Applying patch #{modification.uuid}"
      %x(patch #{tmp_file} #{mod_diff_path})
    end

    # 3. Use diff3 to generate a merged version M
    #   NB: do it nondestructively
    merged_file = File.join(@repo.tmp_path, @fname + '.merged')
    %x(diff3 -L "head #{parents.first.uuid}" -L "base" -L "other #{other.uuid}" -mE #{head_file} #{common_file} #{tmp_file} > #{merged_file})

    # 4. diff M against X and against head to create the patch

    File.open(File.join(@parent_dir, @fname + '.diff'), 'w') {|f| f << %x(diff #{head_file} #{merged_file})}
    @other_dir = File.join(@patch_dir, other.uuid)
    Dir.mkdir(@other_dir) if !File.exist?(@other_dir)
    File.open(File.join(@other_dir, @fname + '.diff'), 'w') {|f| f << %x(diff #{tmp_file} #{merged_file})}

    puts "Merged patches with patch #{uuid}"

    @uuid
  end

  def process_fname(name)
    super(name)

    if name[-5,5] == ".diff"
      return name[0..-6]
    else
      return name
    end
  end

  def type
    "merge"
  end

  def apply(parent_uuid)
    super()
    if !(parent_uuid == parents.first.uuid || parent_uuid == @other_uuid)
      raise "#{parent_uuid} is not a parent of #{@uuid}"
    end
    diff_path = File.join(@patch_dir, parent_uuid, @fname + '.diff')
    %x(patch #{@fname} #{diff_path})
  end

  def unapply(parent_uuid)
    super()
    if !(parent_uuid == parents.first.uuid || parent_uuid == @other_uuid)
      raise "#{parent_uuid} is not a parent of #{@uuid}"
    end
    diff_path = File.join(@patch_dir, parent_uuid, @fname + '.diff')
    %x(patch -R #{@fname} #{diff_path})
    parent_uuid
  end
end
