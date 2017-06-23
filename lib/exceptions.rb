# When the number of hash entries in the argument hash is incorrect
class BadArgumentCount < Exception
  def initialize(expected, actual)
    super("Invalid number of arguments, expected #{expected} got #{actual}")
  end
end

# When a otherwise valid argument is given to a method that only works
# with certain types
class BadArgumentType < Exception
  def initialize(expected, actual)
    super("Invalid argument type, expected #{expected} got #{actual}")
  end
end

# When a value is not of a supported type
class InvalidType < Exception
  def initialize
    super('String, Float, and Integer are the only valid types')
  end
end

# The primary motivation for this class is to be specific when disallowing
# calling into builtin ruby methods
class UndefinedCustomMethod < Exception
  def initialize(actual)
    super("Undefined custom method #{actual}")
  end
end
