class CommandLineObjectWrapper
  attr_reader :obj, :method_to_call, :method_params

  def initialize obj, args
    @obj = obj
    @method_to_call = args[0].to_sym
    @method_params = args.drop(1) 
  rescue Exception => e
    abort e.message
  end

  def execute
    puts "Executing #{method_to_call}"
    if method_params.any?
      obj.send(method_to_call, method_params)
    else
      obj.send(method_to_call)
    end
    puts "Complete"
  rescue Exception => e
    abort e.message
  end
end
