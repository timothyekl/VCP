class ModifyPatch < KennyPatch
  def inspect
    "Modify patch #{@uuid} for file #{@fname}"
  end
  
  def create
    super()
    
    # Need to reconstruct the base file that changes were made to
    changelist = self.find_ancestry(@fname)
    if changelist[0].type != "add"
      raise "File introduced by a patch other than an AddPatch: #{changelist[0]}"
    end
    
    # Copy base file from original add patch
    add_patch_dir = changelist[0].patch_dir
    base_path = Dir.glob(File.join(add_patch_dir, "**", "#{@fname}.base"))[0]
    puts "Base file exists at #{base_path}"
    FileUtils.cp(base_path, @repo.tmp_path)
    tmp_base = File.join(@repo.tmp_path, @fname) + ".base"
    
    # Repeatedly update file
    changelist[1..-2].each do |modification| #includes current patch - need to truncate
      mod_patch_dir = modification.patch_dir
      mod_diff_path = Dir.glob(File.join(mod_patch_dir, "**", "#{@fname}.diff"))[0]
      puts "Patching with diff at #{mod_diff_path}"
      %x(patch #{tmp_base} #{mod_diff_path})
    end
    
    File.open(File.join(@parent_dir, @fname) + ".diff", "w") {|f| f << %x(diff #{tmp_base} #{File.join(@repo.path, @fname)})}
    
    @uuid
  end
  
  def type
    "modify"
  end
  
  def process_fname(name)
    super(name)
    
    if name[-5,5] == ".diff"
      return name[0..-6]
    else
      return name
    end
  end
  
  def apply
    super()
    
    diff_path = File.join(@parent_dir, @fname + ".diff")
    %x(patch #{@fname} #{diff_path})
  end
  
  def unapply
    super()
    
    target_patch = self.find_ancestry(@fname)[-2]
    
    diff_path = File.join(@patch_dir, target_patch.uuid, @fname + ".diff")
    %x(patch -R #{@fname} #{diff_path})
    
    target_patch.uuid
  end
end