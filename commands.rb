require 'lib.rb'

class KennyCommands
  def help(args)
    puts "Usage: kenny <command> [args...]"
    puts "\n"
    puts "\thelp -- this message"
    puts "\tmake -- create a new repo"
    puts "\tcommit file1 [file2 ...] -- commit changes in the listed files"
  end
  
  # create a new repo
  def make(args)
    # TODO implement
  end

  # make a new commit with the files listed
  def commit(args)
    # TODO implement
  end
end