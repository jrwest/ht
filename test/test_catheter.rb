require 'helper'

CASCADE = Catheter::Cascade.new(:my_cascade) do |t|
  t.base do |t, opts|
    t.set_value :item, opts[:item]
    t.set_value :image, "#{opts[:player]}.png"
  end
  
  t.layer name: :contribute_base do |t, opts|
    t.set_value :player, opts[:player]
    t.set_value :image, "#{opts[:item]}.png"
  end
  
  t.layer name: :contribute_part, depends: [:contribute_base] do |t, opts|
    t.set_value :body, t.get_value(:image)
  end
end

OPTS = {:player => "jordanrw", :item => "cool-thing"}

class TestCatheter < MiniTest::Unit::TestCase
  def test_base
    result = CASCADE.build(:base, OPTS)
    
    assert_equal OPTS[:item], result[:item]
    assert_equal "#{OPTS[:player]}.png", result[:image]
  end
  
  def test_one_layer
    result = CASCADE.build(:contribute_base, OPTS)
    
    assert_equal OPTS[:player], result[:player]
    assert_equal "#{OPTS[:item]}.png", result[:image]
  end
  
  def test_two_layers
    result = CASCADE.build(:contribute_part, OPTS)
    
    assert_equal OPTS[:player], result[:player]
    assert_equal OPTS[:item], result[:item]
    assert_equal "#{OPTS[:item]}.png", result[:image]
    assert_equal result[:image], result[:body]
  end
  
  def test_layers_that_depend_on_layers_that_depend_on_layers
    
  end
end
