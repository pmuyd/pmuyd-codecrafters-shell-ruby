BUILTIN = ['exit', 'echo', 'type', 'pwd', 'cd']

def find_executable(cmd)
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        executable = File.join(path, cmd)
        return executable if File.executable?(executable)
    end
    nil
end
  
def execute_external(cmd, args)
    executable = find_executable(cmd)
    if executable
        system(cmd, *args)
    else
        puts "#{cmd}: command not found"
    end
end

def type_cmd(cmd)
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

def cd_cmd(args)
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

def redirect_output(cmd, 
                    args, 
                    output_file, 
                    stderr_file, 
                    append_stdout, 
                    append_stderr)
    original_stdout = $stdout.dup
    original_stderr = $stderr.dup

    stdout_mode = append_stdout ? "a" : "w"
    stderr_mode = append_stderr ? "a" : "w"

    $stdout.reopen(output_file, stdout_mode) if output_file
    $stderr.reopen(stderr_file, stderr_mode) if stderr_file
    
    begin
        if BUILTIN.include?(cmd)
            case cmd

            when 'echo'
                puts args.join(" ")
            when 'type'
                args.each { |cmd| type_cmd(cmd) }
            when 'pwd'
                puts Dir.pwd
            when 'cd'
                cd_cmd(args)
            end
        else
            execute_external(cmd, args)
        end
    ensure
        $stdout.reopen(original_stdout) if output_file
        $stderr.reopen(original_stderr) if stderr_file
    end
end

def setup_redirection(tokens)
    # Find the index of the first redirection operator  
    redirect_indices = {
        output: tokens.index { |token| token == '>' || token == '1>' },
        output_append: tokens.index { |token| token == '>>' || token == '1>>' },
        stderr: tokens.index { |token| token == '2>' },
        stderr_append: tokens.index { |token| token == '2>>' }
    }

    redirect_index = redirect_indices.values.compact.min
    return [nil] * 6 unless redirect_index
  
    # Extract the command, arguments, and redirection files
    command, *args = tokens[0...redirect_index]
    output_file = stderr_file = nil
    append_stdout = append_stderr = false
  
    # Find the output 
    if redirect_indices[:output]
        output_file = tokens[redirect_indices[:output] + 1]
    elsif redirect_indices[:output_append]
        output_file = tokens[redirect_indices[:output_append] + 1]
        append_stdout = true
    end
    
    # Find the stderr
    if redirect_indices[:stderr]
        stderr_file = tokens[redirect_indices[:stderr] + 1]
    elsif redirect_indices[:stderr_append]
        stderr_file = tokens[redirect_indices[:stderr_append] + 1]
        append_stderr = true
    end
  
    [command, args, output_file, stderr_file, append_stdout, append_stderr]
end

# Main loop
loop do 
    $stdout.write("$ ")
    input = gets.chomp
    tokens = parse_input(input)
    
    cmd, args, output_file, stderr_file, append_stdout, append_stderr = setup_redirection(tokens)

    if cmd
        # Redirect output if a redirection operator is present
        redirect_output(cmd, args, output_file, stderr_file, append_stdout, append_stderr)

    else
        cmd, *args = tokens
        
        case cmd
        when 'exit'
            break
        when 'echo'
            puts args.join(" ")
        when 'type'
            args.each { |cmd| type_cmd(cmd) }
        when 'pwd'
            puts Dir.pwd
        when 'cd'
            cd_cmd(args)
        else
            execute_external(cmd, args)
        end
    end
end