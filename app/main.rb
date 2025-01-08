COMMANDS = ['exit', 'echo', 'type', 'pwd', 'cd', 'cat']

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

def cd_command(args)
    if args.empty?
      # Change to home directory if no argument is provided
      Dir.chdir(ENV['~'] || '/')
    else
      begin
        Dir.chdir(File.expand_path(args[0]))
      rescue Errno::ENOENT
        puts "cd: #{args[0]}: No such file or directory"
      end
    end
  end

def echo_command(input)
    # Remove the 'echo' command from the input
    message = input.sub(/^\s*echo\s+/, '')
    
    # Handle single-quoted strings
    if message.start_with?("'") && message.end_with?("'")
      puts message[1..-2]  # Remove the surrounding quotes
    else
      puts message
    end
end

def cat_command(args)    
    args.each do |file|
      begin
        File.open(file, 'r') do |f|
          f.each_line { |line| puts line }
        end
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
        echo_command(input)
    when 'type'
        args.each { |cmd| type_command(cmd) }
    when 'pwd'
        puts Dir.pwd
    when 'cd'
        cd_command(args)
    when 'cat'
        cat_command(args)
    else
        execute_external(command, args)
    end
end
