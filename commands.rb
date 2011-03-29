require File.dirname(__FILE__) + File::Separator + 'lib.rb'

class KennyCommands
  def help(args)
    puts "Usage: kenny <command> [args...]"
    puts "\n"
    puts "\thelp -- displays this message"
    puts "\tinfo [dir] -- give information about the repository in the given directory"
    puts "\tinit [dir] -- initialize a repository in specified directory"
    puts "\tadd file -- make a patch to add a newly created (unversioned) file"
    puts "\tremove file -- make a patch to remove a file"
    puts "\tcommit file1 [file2 ...] -- commit changes in the listed (versioned) files"
    puts "\t"
    puts "\tdebug <cmd> [args ...] -- perform debugging actions (development only)"
    puts "\t                          must be in kenny repo"
  end

  def info(args)
    if args.length == 1
      path = args[0]
    else
      path = "."
    end

    puts KennyRepo.new(path).info
  end

  # create a new repo
  def init(args)
    if args.length == 1
      path = args[0]
    else
      path = "."
    end

    KennyRepo.new(path).init_repo

    puts 'Repository initialized.'
  end

  # make a new commit with the files listed
  def commit(args)
    args.each do |fname|
      KennyRepo.new(".").make_modify_patch(fname)
    end
  end

  # add a newly created file
  def add(args)
    fname = args[0]
    KennyRepo.new(".").make_add_patch(fname)

    puts fname + ' is now being tracked/remembered.'
  end

  # apply a patch to the current repository
  def apply(args)
    uuid = args[0]
    KennyRepo.new(".").apply_patch(uuid)

    puts 'Patched repository with patch uuid ' + uuid + '.'
  end

  # unapply a patch to the current repository
  def unapply(args)
    uuid = args[0]
    KennyRepo.new(".").unapply_patch(uuid)

    puts 'Unpatched repository with patch uuid ' + uuid + '.'
  end

  # remove a file
  def remove(args)
    # TODO
  end
  
  def debug(args)
    command = args[0]
    debug_args = args[1..-1]
    
    case command
    when "list"
      puts "\tlist -- this list"
      puts "\tpfu <uuid> -- inspect a patch for a given UUID"
      puts "\tancestry <uuid> -- show the ancestry of a given patch UUID"
    when "pfu"
      uuid = debug_args[0]
      puts KennyRepo.new(".").patch_for_uuid(uuid).inspect
    when "ancestry"
      uuid = debug_args[0]
      if !uuid.nil?
        uuid = uuid.to_s
        patch = KennyRepo.new(".").patch_for_uuid(uuid)
        ancestry = patch.find_ancestry(patch.fname)
        ancestry.each { |ancestor| puts ancestor.inspect }
      end
    end
  end
end
