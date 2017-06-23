require 'json'
require 'execution_space'

# Processes a fsl script. Primarily serves to prevent the
# execution space from having to know anything about json.
class FSLProcessor

  # Process a list of filenames, calling init after each file if
  # init has been defined by any script parsed
  # @param [Array] filenames An array of filenames
  def self.process_all(filenames)

    # create an execution space to evaluate the given scripts
    execution_space = ExecutionSpace.new

    filenames.each do |filename|
      begin
        # parse and call init for each given script
        FSLProcessor.parse(File.read(filename), execution_space)
        execution_space.init if execution_space.respond_to?(:init)
      rescue => e
        puts "Error while processing #{filename}"
        raise
      end
    end

  end

  # Parse a single io object into the given space, or
  # create a new space if one isn't given
  # @param [IO] io An io object
  # @param [ExecutionSpace] exe_space Space to define directives from
  #  given script
  def self.parse(io, exe_space=nil)

    # create a new space if one isn't given
    exe_space = ExecutionSpace.new if exe_space.nil?

    json_script = JSON.parse(io)

    # Array isn't a valid fsl type, so we can assume a given
    # array means a function definition
    json_script.each do |key, value|
      if Array === value
        ExecutionSpace.create_fsl_method(key, value)
      else
        exe_space.instance_variable_set("@#{key}", value)
      end
    end

    # return the space used to parse the given script
    exe_space
  end
end
