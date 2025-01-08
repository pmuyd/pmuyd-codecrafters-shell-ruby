COMMANDS = ['exit', 'echo', 'type']

def type_command(cmd)
  if COMMANDS.include?(cmd)
    puts "#{cmd} is a shell builtin"
  else
    puts "#{cmd} not found"
  end
end

loop do 
    $stdout.write("$ ")
    input = gets.chomp
    command, *args = input.split(" ")

    case command
    when 'exit'
        break
    when 'echo'
        puts args.join(" ")
    when 'type'
        args.each { |cmd| type_command(cmd) }
    else
        puts "#{command}: command not found"
    end
end
