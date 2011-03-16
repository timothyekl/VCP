require File.dirname(__FILE__) + File::Separator + 'lib.rb'

class KennyCommands
  def help(args)
    puts "Usage: kenny <command> [args...]"
    puts "\n"
    puts "\thelp -- this message"
    puts "\tmake [path] -- create a new repo in the directory pointed to by path"
    puts "\tadd file -- make a patch to add a newly created (unversioned) file"
    puts "\tremove file -- make a patch to remove file"
    puts "\tcommit file1 [file2 ...] -- commit changes in the listed (versioned) files"
  end
  
  # create a new repo
  def make(args)
    if args.length == 1
      path = args[0]
    else
      path = "."
    end
    
    KennyRepo.new(path).make_repo
  end

  # add a newly created file
  def add(args)
    path = args[0]
    KennyRepo.new(".").make_add_patch(path)
  end

  # remove a file
  def remove(args)
    # TODO
  end

  # make a new commit with the files listed
  def commit(args)
    # TODO implement
  end
end