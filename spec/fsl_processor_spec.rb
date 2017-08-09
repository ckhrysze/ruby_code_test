require 'spec_helper'

describe FSLProcessor do
  describe "self.parse" do
    it 'should parse variables into a new space' do
      json = '{ "a" : "asdf" }'

      space = FSLProcessor.parse(json)
      expect(space.instance_variable_get("@a")).to eq("asdf")
    end

    it 'should parse variables into the given space' do
      json = '{ "a" : "asdf" }'

      space = ExecutionSpace.new
      FSLProcessor.parse(json, space)
      expect(space.instance_variable_get("@a")).to eq("asdf")
    end

    it 'should raise an error if a variable contains illegal characters' do
      json = '{ "#a" : "asdf" }'

      expect {
        FSLProcessor.parse(json)
      }.to raise_error(NameError)
    end
  end
end
