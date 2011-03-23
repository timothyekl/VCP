require File.dirname(__FILE__) + File::Separator + 'lib.rb'

class KennyCommands
  def help(args)
    puts "Usage: kenny <command> [args...]"
    puts "\n"
    puts "\thelp -- displays this message"
    puts "\tinit [dir] -- initialize a repository in specified directory"
    puts "\tadd file -- make a patch to add a newly created (unversioned) file"
    puts "\tremove file -- make a patch to remove a file"
    puts "\tcommit file1 [file2 ...] -- commit changes in the listed (versioned) files"
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
    # TODO implement
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
    KennyRepo.new(".").apply_add_patch(uuid)

    puts 'Patched repository with patch ' + uuid + '.'
  end

  # remove a file
  def remove(args)
    # TODO
  end
end
