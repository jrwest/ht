require 'helper'

class TestBuilder < MiniTest::Unit::TestCase

  def setup
    @cascade = HT::Cascade.new(:my_cascade) do
      base do |res, opts|
        res.set_value :item, opts[:item]
        res.set_value :image, "#{opts[:player]}.png"
      end
  
      layer :contribute_base do |res, opts|
        res.set_value :player, opts[:player]
        res.set_value :image, "#{opts[:item]}.png"
      end
  
      layer :contribute_part, :contribute_base do |res, opts|
        res.set_value :body, res.get_value(:image)
      end
  
      layer :contribute_part_1, :contribute_base do |res, opts|
        res.set_value :body, "zxy"
        res.set_value :field, "def"
        res.set_value :field2, "123"
      end
  
      layer :contribute_super, :contribute_part do |res, opts|
        res.set_value :field, res.get_value(:image)
        res.set_value :body, "abc"
      end
  
    end
    
    @opts = {:player => "jordanrw", :item => "cool-thing"}
    @builder = HT::Builder.new
  end

  def test_build_dependency_list_base_case
    cascade = {base: {depends: nil, block: nil}}
    
    assert_equal [], @builder.dependency_list(cascade, :base)
  end

  def test_build_dependency_base_case_when_layers_exist
    cascade = {base: {depends: nil, block: nil}, contribute_base: {depends: :base, block: nil}}
    
    assert_equal [], @builder.dependency_list(cascade, :base)
  end
   
  
  def test_build_dependency_one_layer_up
    cascade = {base: {depends: nil, block: nil}, 
               contribute_base: {depends: :base, block: nil}}
                
    assert_equal [:base], @builder.dependency_list(cascade, :contribute_base)
  end
   
  def test_build_dependency_two_layers_up
    cascade = {base: {depends: nil, block: nil}, 
               contribute_base: {depends: :base, block: nil},
               contribute_part: {depends: :contribute_base, block: nil}}
     
    assert_equal [:contribute_base, :base] , @builder.dependency_list(cascade, :contribute_part)
  end
   
  def test_build_dependency_three_layers_up
    cascade = {base: {depends: nil, block: nil}, 
               contribute_base: {depends: :base, block: nil},
               contribute_part: {depends: :contribute_base, block: nil},
               contribute_part_2: {depends: :contribute_part, block: nil}}
                
    assert_equal [:contribute_part, :contribute_base, :base] , @builder.dependency_list(cascade, :contribute_part_2)
  end
   
  def test_build_dependency_six_layers_up
    cascade = {base: {depends: nil}, block: nil, 
               contribute_base: {depends: :base, block: nil},
               contribute_part: {depends: :contribute_base, block: nil},
               contribute_part_2: {depends: :contribute_part, block: nil}, 
               contribute_part_3: {depends: :contribute_part_2, block: nil},
               contribute_part_4: {depends: :contribute_part_3, block: nil},
               contribute_part_5: {depends: :contribute_part_4, block: nil}}
     
    expected = [:contribute_part_4, :contribute_part_3, :contribute_part_2, :contribute_part, :contribute_base, :base]
     
     
    assert_equal [], @builder.dependency_list(cascade, :base)
    assert_equal [:contribute_part_2, :contribute_part, :contribute_base, :base], @builder.dependency_list(cascade, :contribute_part_3)
    assert_equal expected, @builder.dependency_list(cascade, :contribute_part_5)
  end

  def test_base
    result = @builder.run(@cascade, @opts, :base)
    
    assert_equal @opts[:item], result[:item]
    assert_equal "#{@opts[:player]}.png", result[:image]
  end
   
  def test_one_layer
    result = @builder.run(@cascade, @opts, :contribute_base)
    
    assert_equal @opts[:player], result[:player]
    assert_equal "#{@opts[:item]}.png", result[:image]
  end
  
  def test_two_layers
    result = @builder.run(@cascade, @opts, :contribute_super)
    
    assert_equal @opts[:player], result[:player]
    assert_equal @opts[:item], result[:item]
    assert_equal "#{@opts[:item]}.png", result[:field]
    assert_equal "abc", result[:body]
  end
 
end
