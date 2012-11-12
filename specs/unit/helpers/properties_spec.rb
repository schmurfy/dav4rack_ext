require File.expand_path('../../../spec_helper', __FILE__)

describe 'inheritable propertie' do
  before do
    @klass_a = Class.new do
      extend Helpers::Properties
      
      define_properties('ns1') do
        property('name'){ "name1" }
        property('dynamic'){ 4 + @a }
      end
    end
    
    @klass_b = Class.new(@klass_a) do
      define_properties('ns1') do
        property('dynamic'){ 10 + @a }
      end
      
      define_properties('ns2') do
        property('another_value'){ "test" }
      end
    end
    
  end
  
  describe 'on base class' do
    should 'return correct values' do
      @klass_a.properties['ns1*name'][0].call.should == "name1"
    end
    
    should 'execute block in context' do
      @a = 42
      blk = @klass_a.properties['ns1*dynamic'][0]
      instance_eval(&blk).should == 46
    end
    
    should 'not return child class properties' do
      @klass_a.properties['ns2*another_value'].should == nil
    end
  end
  
  describe 'on child class' do
    should 'return correct values' do
      @klass_b.properties['ns1*name'][0].call.should == "name1"
    end
    
    should 'execute block in context' do
      @a = 42
      blk = @klass_b.properties['ns1*dynamic'][0]
      instance_eval(&blk).should == 52
    end
    
    should 'return specific value' do
      @klass_b.properties['ns2*another_value'][0].call.should == "test"
    end
  end
  
end
