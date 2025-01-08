COMMANDS = ['exit', 'echo', 'type']

def execute_command(command, *args)
    begin
      pid = spawn(command, *args)
      Process.wait(pid)
    rescue Errno::ENOENT
      puts "#{command}: command not found"
    end
  end

def type_command(cmd)
  if COMMANDS.include?(cmd)
    puts "#{cmd} is a shell builtin"
  else
    path = ENV['PATH'].split(':')
    executable_path = path.find { |dir| File.executable?(File.join(dir, cmd)) }
    if executable_path
      puts "#{cmd} is #{File.join(executable_path, cmd)}"
    else
      puts "#{cmd} not found"
    end
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
