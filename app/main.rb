

loop do 
    $stdout.write("$ ")
    input = gets.chomp
    command, *args = input.split(" ")

    case command
    when 'exit'
        break
    when 'echo'
        puts args.join(" ")
    else
        puts "#{command}: command not found"
    end
end
