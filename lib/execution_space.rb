require 'exceptions'

# The class on which fsl variables and methods
# are defined
class ExecutionSpace

  # Create a new method for any instance of this class. If instances
  # of this class need to have different methods than others, this
  # would need to change to create methods on the eigen class instead
  # @param [String] name The function name
  # @param [Array] function The array of commands comprising the funtion
  def self.create_fsl_method(name, function)

    name = name.to_sym
    raise "Cannot override native methods" if @@fsl_methods.include?(name)

    @@custom_methods << name
    
    define_method(name) do |*args|

      # if there are any args, its the hash of paramaters to a
      # custom method
      method_arguments = args.first

      # loop through each line of a fsl function
      function.each do |function_line|

        # clone the hash so we can delete the require 'cmd' key without
        # affecting the next call
        cmd_line = function_line.dup

        # pull out of the cmd, raise an error if it is not given
        cmd = cmd_line.delete('cmd')

        raise "No command given" unless cmd

        if cmd =~ /^#(.+)/
          # the cmd specified a custom method, call it or raise an error
          # if it is not defined
          cmd = $1
          unless @@custom_methods.include?(cmd.to_sym)
            raise UndefinedCustomMethod.new(cmd)
          end

          # pass the rest of the line to the custom method as a hash
          self.send(cmd, paramaterize(cmd_line, method_arguments, false))

        else
          unless @@fsl_methods.include?(cmd.to_sym)
            raise "Native method #{cmd} does not exist"
          end

          if cmd == 'print'
            # Null is not a valid type, yet print does not throw an
            # exception, so it is a special case
            self.print(paramaterize(cmd_line, method_arguments, false))
          else
            # the cmd specified is a native method, resolve the arguments
            # and call the method
            self.send(cmd, paramaterize(cmd_line, method_arguments))
          end
        end
      end
    end
  end

  #
  # Define the native methods in the fsl language
  #

  # Create a new instance variable
  # @param [Hash] params The method arguments
  def create(params)
    raise BadArgumentCount.new(2, params.count) unless params.count == 2

    var = params['id']
    value = params['value']

    raise "Create requires id and a value" unless var && value

    var = "@#{var}"
    if instance_variable_defined?(var)
      raise "Instance variable #{var} should not be defined"
    end

    self.instance_variable_set(var, value)
  end

  # Updates the value of an instance variable
  # @param [Hash] params The method arguments
  def update(params)
    raise BadArgumentCount.new(2, params.count) unless params.count == 2

    var = params['id']
    value = params['value']

    raise "Update requires id and value" unless var && value

    var = "@#{var}"
    unless instance_variable_defined?(var)
      raise "Instance variable #{var} should be defined"
    end

    self.instance_variable_set(var, value)
  end

  # Deletes an instance variable
  # @param [Hash] params The method arguments
  def delete(params)
    raise BadArgumentCount.new(1, params.count) unless params.count == 1

    var = params['id']

    raise "Delete requires id" unless var

    var = "@#{var}"
    unless instance_variable_defined?(var)
      raise "Instance variable #{var} should be defined"
    end

    self.instance_variable_set(var, nil)
  end

  # Adds two numbers
  # @param [Hash] params The method arguments
  def add(params)
    operate(params) { |operand1, operand2| operand1 + operand2 }
  end

  # Substracts two numbers
  # @param [Hash] params The method arguments
  def subtract(params)
    operate(params) { |operand1, operand2| operand1 - operand2 }
  end

  # Multiplies two numbers
  # @param [Hash] params The method arguments
  def multiply(params)
    operate(params) { |operand1, operand2| operand1 * operand2 }
  end

  # Divides two numbers
  # @param [Hash] params The method arguments
  def divide(params)
    operate(params) { |operand1, operand2| operand1 / operand2 }
  end

  # Prints the value
  # @param [Hash] params The method arguments
  def print(params)
    raise BadArgumentCount.new(1, params.count) unless params.count == 1

    value = if params['value'] =~ /^#(.+)/
              self.instance_variable_get("@#{$1}")
            else
              params['value']
            end

    puts value || 'undefined'
  end


  # List of defined methods to prevent fsl scripts from
  # calling existing ruby object methods
  @@fsl_methods = self.public_instance_methods(false)

  # List of custom methods also used to control what can
  # be invoked
  @@custom_methods = []

  private

  # Lookup cmd arguments in the method arguments when appropiate, and
  # optionally resolve variables
  def paramaterize(command_hash, method_hash, should_resolve=true)

    params = {}

    command_hash.each do |key, value|
      param = value
      if value =~ /^\$(.+)/
        # custom method parameter, so resolve the value keyed
        # to the given parameter
        arg_key = $1
        param = method_hash[arg_key]
      end

      param = should_resolve ? resolve(param) : param
      params[key] = param
    end

    params
  end

  # Resolves a variable. If the argument is a string and
  # begins with a #, treat it as an instance variable.
  def resolve(variable)
    value = if variable =~ /^#(.+)/
              self.instance_variable_get("@#{$1}")
            else
              variable
            end
    raise InvalidType.new unless Numeric === value || String === value

    value
  end

  # Abstract away everything about the math operations aside from
  # the operation itself
  def operate(params)
    raise BadArgumentCount.new(3, params.count) unless params.count == 3

    var = params['id']
    operand1 = params['operand1']
    operand2 = params['operand2']

    # non string non numeric types should have raised an exception before
    # reaching this point
    raise BadArgumentType.new(String, var.class) unless String === var
    raise BadArgumentType.new(Numeric, String) if String === operand1
    raise BadArgumentType.new(Numeric, String) if String === operand2

    # yield back to the calling method to perform the actual operation
    result = yield operand1, operand2

    self.instance_variable_set("@#{var}", result)
  end


end
