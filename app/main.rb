COMMANDS = ['exit', 'echo', 'type', 'pwd']

def find_executable(cmd)
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      executable = File.join(path, cmd)
      return executable if File.executable?(executable)
    end
    nil
  end
  
  def execute_external(command, args)
    executable = find_executable(command)
    if executable
      system(command, *args)
    else
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
    when 'pwd'
        puts Dir.pwd
    else
        execute_external(command, args)
    end
end
