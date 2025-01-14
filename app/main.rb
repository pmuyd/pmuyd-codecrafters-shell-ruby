BUILTIN = ['exit', 'echo', 'type', 'pwd', 'cd']

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
    if BUILTIN.include?(cmd)
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

def cat_command(args)
    if args.empty?
        while line = gets
            print line
        end
    else
        args.each do |file|
            begin
                File.open(file, 'r') do |f|
                    print f.read
                end
            rescue Errno::ENOENT
                $stderr.puts "cat: #{file}: No such file or directory"
            end
        end
    end
end

def parse_input(input)
    tokens = []
    current_token = ''
    quote_char = nil
    escape_next = false
  
    input.each_char.with_index do |char, i|
        if escape_next
            current_token << char
            escape_next = false
        elsif char == '\\' && quote_char != "'"
            if quote_char == '"' && !["\\", "$", '"', "\n"].include?(input[i+1])
                current_token << char
            else
                escape_next = true
            end
        elsif quote_char.nil? && (char == "'" || char == '"')
            quote_char = char
        elsif char == quote_char
            quote_char = nil
        elsif char == ' ' && quote_char.nil?
            tokens << current_token unless current_token.empty?
            current_token = ''
        else
            current_token << char
        end
    end

    tokens << current_token unless current_token.empty?
    tokens
end

loop do 
    $stdout.write("$ ")
    input = gets.chomp
    tokens = parse_input(input)
    command, *args = tokens

    case command
    when 'exit'
        break
    when 'echo'
        puts args.join(" ")
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
