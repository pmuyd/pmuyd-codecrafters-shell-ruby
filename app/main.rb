COMMANDS = ['exit']

loop do 
    $stdout.write("$ ")
    command, *args = gets.chomp.split(" ")

    puts "#{command}: command not found" unless COMMANDS.include?(command)

    break if command == 'exit'
end
