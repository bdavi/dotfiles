class SimpleCLIWrapper
  attr_accessor :args, :klass

  def initialize(args, klass)
    @klass = klass
    @args = args
  end

  def perform
    if _valid_commands.include?(_command)
      puts "Executing: #{_command}..."
      klass.new.send(*args)
      puts 'Complete'
    else
      puts _invalid_command_message
    end
  end

private
  def _command
    args.first
  end

  def _invalid_command_message
    puts "Please use one of these valid commands: #{valid_commands.join(', ')}."
  end

  def _valid_commands
    (klass.public_instance_methods - Object.public_methods).map(&:to_s).sort
  end
end
