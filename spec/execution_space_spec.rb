require 'spec_helper'

describe ExecutionSpace do

  describe 'self.create_fsl_method' do
    it 'should create a new method when none by the given name exist' do
      name = 'brand_new'
      ExecutionSpace.create_fsl_method(name, [])
      ExecutionSpace.public_instance_methods(false).should include(name.to_sym)
    end

    it 'should override a custom method when one by the given name exists' do
      name = 'twice'
      create_cmd = {"cmd" => "create", "id" => "a", "value" => 5}

      ExecutionSpace.create_fsl_method(name, [])
      ExecutionSpace.create_fsl_method(name, [create_cmd])

      space = ExecutionSpace.new
      space.send(name)

      space.instance_variable_get("@a").should == 5
    end

    it 'should raise an error when attempting to override a native method' do
      lambda {
        ExecutionSpace.create_fsl_method('create', [])
      }.should raise_error
    end
  end

  describe 'custom methods' do
    it 'should raise an error when a cmd calls a ruby method' do
      ExecutionSpace.create_fsl_method('test', [{'cmd' => '#respond_to?'}])

      space = ExecutionSpace.new
      lambda {
        space.send('test')
      }.should raise_error(UndefinedCustomMethod)
    end
  end

  describe 'create' do
    before do
      @space = ExecutionSpace.new
    end

    it 'should set the value of an instance variable' do
      @space.create({'id' => 'a', 'value' => 3})

      @space.instance_variable_get('@a').should == 3
    end

    it 'should raise an error when too many arguments are given' do
      lambda {
        @space.create({'id' => 'a', 'value' => 3, 'extra' => 2})
      }.should raise_error(BadArgumentCount)
    end

    it 'should raise an error when too few arguments are given' do
      lambda {
        @space.create({'id' => 'a'})
      }.should raise_error(BadArgumentCount)
    end

    it 'should raise an error if the variable is defined' do
      @space.create({'id' => 'a', 'value' => 3})

      lambda {
        @space.create({'id' => 'a', 'value' => 3})
      }.should raise_error
    end

    it 'should raise an error when id is not given' do
      lambda {
        @space.create({'var' => 'a', 'value' => 4})
      }.should raise_error
    end

    it 'should raise an error when the value is not given' do
      lambda {
        @space.create({'id' => 'a', 'value1' => 3})
      }.should raise_error
    end
  end

  describe 'update' do
    before do
      @space = ExecutionSpace.new
    end

    it 'should update the value of an instance variable' do
      @space.instance_variable_set('@a', 3)
      @space.update({'id' => 'a', 'value' => 4})

      @space.instance_variable_get('@a').should == 4
    end

    it 'should raise an error when too many arguments are given' do
      lambda {
        @space.update({'id' => 'a', 'value' => 3, 'extra' => 2})
      }.should raise_error(BadArgumentCount)
    end

    it 'should raise an error when too few arguments are given' do
      lambda {
        @space.update({'id' => 'a'})
      }.should raise_error(BadArgumentCount)
    end

    it 'should raise an error if the variable is not defined' do
      lambda {
        @space.update({'id' => 'a', 'value' => 3})
      }.should raise_error
    end

    it 'should raise an error when id is not given' do
      lambda {
        @space.update({'var' => 'a', 'value' => 4})
      }.should raise_error
    end

    it 'should raise an error when the value is not given' do
      lambda {
        @space.udpate({'id' => 'a', 'value1' => 3})
      }.should raise_error
    end
  end

  describe 'delete' do
    before do
      @space = ExecutionSpace.new
    end

    it 'should delete the value of an instance variable' do
      @space.instance_variable_set('@a', 3)
      @space.delete({'id' => 'a'})

      @space.instance_variable_get('@a').should be_nil
    end

    it 'should raise an error when too many arguments are given' do
      lambda {
        @space.delete({'id' => 'a', 'value' => 3})
      }.should raise_error(BadArgumentCount)
    end

    it 'should raise an error if the variable is not defined' do
      lambda {
        @space.delete({})
      }.should raise_error
    end

    it 'should raise an error when id is not given' do
      lambda {
        @space.delete({'var' => 'a'})
      }.should raise_error
    end
  end

  # shared specs for the math operations
  shared_examples "an operation" do |operation|
    let(:space) { ExecutionSpace.new }

    it 'should raise an error if id is not a string' do
      params = {
        'id' => 5,
        'operand1' => 6,
        'operand2' => 3
      }

      lambda {
        space.send(operation, params)
      }.should raise_error(BadArgumentType)
    end

    it 'should raise an error if operand1 is a string' do
      params = {
        'id' => 'a',
        'operand1' => '6',
        'operand2' => 3
      }

      lambda {
        space.send(operation, params)
      }.should raise_error(BadArgumentType)
    end

    it 'should raise an error if operand2 is a string' do
      params = {
        'id' => 'a',
        'operand1' => 6,
        'operand2' => '3'
      }

      lambda {
        space.send(operation, params)
      }.should raise_error(BadArgumentType)
    end

    it 'should raise an error if not given exactly 3 parameters' do
      too_few = {
        'id' => 'a',
        'operand1' => 1
      }

      too_many = {
        'id' => 'a',
        'operand1' => 2,
        'operand2' => 1,
        'operand3' => 3
      }

      lambda {
        space.send(operation, too_few)
      }.should raise_error(BadArgumentCount)

      lambda {
        space.send(operation, too_many)
      }.should raise_error(BadArgumentCount)
    end
  end

  describe 'add' do
    it_should_behave_like("an operation", :add)

    it 'should add the operands' do
      space = ExecutionSpace.new
      space.add({'id' => 'a', 'operand1' => 4, 'operand2' => 3})

      space.instance_variable_get('@a').should == 7
    end
  end

  describe 'subtract' do
    it_should_behave_like("an operation", :subtract)

    it 'should add the operands' do
      space = ExecutionSpace.new
      space.subtract({'id' => 'a', 'operand1' => 4, 'operand2' => 3})

      space.instance_variable_get('@a').should == 1
    end
  end

  describe 'multiply' do
    it_should_behave_like("an operation", :multiply)

    it 'should add the operands' do
      space = ExecutionSpace.new
      space.multiply({'id' => 'a', 'operand1' => 4, 'operand2' => 3})

      space.instance_variable_get('@a').should == 12
    end
  end

  describe 'divide' do
    it_should_behave_like("an operation", :divide)

    it 'should add the operands' do
      space = ExecutionSpace.new
      space.divide({'id' => 'a', 'operand1' => 12, 'operand2' => 3})

      space.instance_variable_get('@a').should == 4
    end
  end

  describe 'print' do
    before do
      @space = ExecutionSpace.new
    end

    it 'should raise an error when too many arguments are given' do
      lambda {
        @space.print({'id' => 'a', 'value' => 'asdf'})
      }.should raise_error(BadArgumentCount)
    end

    it 'should raise an error when too few arguments are given' do
      lambda {
        @space.print({})
      }.should raise_error(BadArgumentCount)
    end
  end

end
