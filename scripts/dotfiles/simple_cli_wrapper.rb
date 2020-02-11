# frozen_string_literal: true

# Passes cli arguments to class methods
class SimpleCLIWrapper
  def initialize(args, klass)
    @klass = klass
    @args = args
  end

  def perform
    if _is_valid?
      _execute
    else
      puts _invalid_message
    end
  end

  private

  attr_accessor :args, :klass

  def _command
    args.first
  end

  def _valid_commands
    (klass.public_instance_methods - Object.public_methods).map(&:to_s).sort
  end

  def _is_valid?
    _valid_commands.include?(_command)
  end

  def _execute
    puts "Executing: #{_command}..."
    klass.new.public_send(*args)
    puts 'Complete'
  end

  def _invalid_message
    "Please use one of these valid commands: #{valid_commands.join(', ')}."
  end
end
