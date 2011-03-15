require 'commands.rb'

# Define list of commands
commands = ["help", "make", "commit"]

# Parse args
command = ARGV[0]

if commands.include?(command)
  KennyCommands.new.send(command.to_s, ARGV[1..ARGV.length])
else
  puts "Commands: " + commands.join(" ")
end