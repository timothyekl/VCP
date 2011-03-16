require File.dirname(__FILE__) + File::Separator + 'commands.rb'

def num_args_ok?(command, num_args)
  if command == "help"
    return true
  end
  if command == "make" && [0,1].include?(num_args)
    return true
  end
  if command == "add" && num_args == 1
    return true
  end
  if command == "remove" && num_args == 1
    return true
  end
  if command == "commit" && num_args >= 1
    return true
  end
  return false
end

# Define list of commands
commands = ["help", "make", "commit", "add", "remove"]

# Parse args
command = ARGV[0]

if commands.include?(command) && num_args_ok?(command, ARGV.size - 1)
  KennyCommands.new.send(command, ARGV[1..ARGV.length])
else
  KennyCommands.new.send("help", ARGV[1..ARGV.length])
end
