require 'helper'

class TestBuilder < MiniTest::Unit::TestCase

  def setup
    @cascade = HT::Cascade.new(:my_cascade) do
      base do |data|
        set :item, data[:item]
        s :image, "#{data[:player]}.png"
      end
  
      layer :contribute_base do 
        set_value :player, data[:player]
        set_value :image, "#{data[:item]}.png"
      end
  
      layer :contribute_part, :contribute_base do |data|
        set_value :body, get(:image)
      end
  
      layer :contribute_part_1, :contribute_base do |data|
        set_value :body, "zxy"
        set_value :field, "def"
        set_value :field2, "123"
      end
  
      layer :contribute_super, :contribute_part do |data|
        set_value :field, get_value(:image)
        set_value :body, "abc"
      end
  
    end
    
    @data = {:player => "jordanrw", :item => "cool-thing"}
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
    result = @builder.run(@cascade, @data, :base)
    
    assert_equal @data[:item], result[:item]
    assert_equal "#{@data[:player]}.png", result[:image]
  end
   
  def test_one_layer
    result = @builder.run(@cascade, @data, :contribute_base)
    
    assert_equal @data[:player], result[:player]
    assert_equal "#{@data[:item]}.png", result[:image]
  end
  
  def test_two_layers
    result = @builder.run(@cascade, @data, :contribute_super)
    
    assert_equal @data[:player], result[:player]
    assert_equal @data[:item], result[:item]
    assert_equal "#{@data[:item]}.png", result[:field]
    assert_equal "abc", result[:body]
  end
 
  def test_builder_is_implicit_receiver_of_block
    builder = @builder
    tester = self
    cascade = HT::Cascade.new(:a_cascade) do
      base do |data|
        tester.assert_equal builder, self
      end
    end
    
    builder.run(cascade, @data, :base)
  end

  def test_input_data_is_not_writeable
    cascade = HT::Cascade.new(:some_cascade) do 
      base do 
        data[:a] = 2
      end
    end

    assert_raises RuntimeError do 
      @builder.run(cascade, {a: 1}, :base) 
    end
  end

  def test_be_backwards_compat_with_0_dot_0_dot_0
    cascade = HT::Cascade.new(:my_cascade) do |t|
      t.base do |t, data|
        t.set_value :d, "abc"
      end

      t.layer :path_share do |t, data|
        t.set_value :a, data[:a]
        t.set_value :b, data[:b]
      end
    end

    assert_equal 1, HT::Builder.new.run(cascade, {a: 1, b: 2}, :path_share)[:a]
  end
end
