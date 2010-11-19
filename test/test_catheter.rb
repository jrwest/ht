require 'helper'

CASCADE = Catheter::Cascade.new(:my_cascade) do |t|
  t.base do |t, opts|
    t.set_value :item, opts[:item]
    t.set_value :image, "#{opts[:player]}.png"
  end
  
  t.layer name: :contribute_base do
    t.set_value :player, opts[:player]
    t.set_value :image, "#{opts[:item]}.png"
  end
  
  t.layer name: :contribute_part, depends: [:contribute_part] do
    t.set_value :body, get_value(:image)
  end
end

class TestCatheter < MiniTest::Unit::TestCase
  def test_base
    opts = {:player => "jordanrw", :item => "cool-thing"}
    result = CASCADE.build(:base, opts)
    
    assert_equal opts[:item], result[:item]
    assert_equal "#{opts[:player]}.png", result[:image]
  end
end
