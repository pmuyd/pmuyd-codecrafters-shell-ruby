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

def redirect_output(command, args, output_file, stderr_file, append_mode)
    original_stdout = $stdout.dup
    original_stderr = $stderr.dup

    output_mode = append_mode ? "a" : "w"
    $stdout.reopen(output_file, output_mode) if output_file
    $stderr.reopen(stderr_file, "w") if stderr_file
    
    begin
        if BUILTIN.include?(command)
            case command

            when 'echo'
                puts args.join(" ")
            when 'type'
                args.each { |cmd| type_command(cmd) }
            when 'pwd'
                puts Dir.pwd
            when 'cd'
                cd_command(args)
            end
        else
            execute_external(command, args)
        end
    ensure
        $stdout.reopen(original_stdout) if output_file
        $stderr.reopen(original_stderr) if stderr_file
    end
end

loop do 
    $stdout.write("$ ")
    input = gets.chomp
    tokens = parse_input(input)
    
    output_redirect_index = tokens.index { |t| t == '>' || t == '1>' }
    output_append_index = tokens.index { |t| t == '>>' || t == '1>>' }
    stderr_redirect_index = tokens.index { |t| t == '2>' }
    
    if output_redirect_index || stderr_redirect_index || output_append_index
        redirect_index = [output_redirect_index, output_append_index, stderr_redirect_index].compact.min
        command, *args = tokens[0...redirect_index]
        
        output_file = nil
        stderr_file = nil
        append_mode = false

        if output_redirect_index
            output_file = tokens[redirect_index + 1]
        elsif output_append_index
            output_file = tokens[redirect_index + 1]
            append_mode = true
        end
        
        stderr_file = tokens[redirect_index + 1] if stderr_redirect_index
        redirect_output(command, args, output_file, stderr_file, append_mode)
    else
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
        else
            execute_external(command, args)
        end
    end
end