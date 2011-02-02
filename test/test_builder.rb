require 'helper'

class TestBuilder < MiniTest::Unit::TestCase

  def setup
    HT::Cascade.flush_global # remove all global cascades to prevent future issues

    @cascade_name = :my_cascade
    @cascade = HT::Cascade.new(@cascade_name) do
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

  def test_when_no_base_exists 
    cascade = HT::Cascade.new do
      layer :layer_1 do
        s :a, 1
      end
    end

    assert_equal 1, @builder.run(cascade, {}, :layer_1)[:a]
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
  
  def test_build_by_cascade_name_when_cascade_exists
    result = @builder.run(@cascade_name, @data, :contribute_super)
    
    assert_equal @data[:player], result[:player]
    assert_equal @data[:item], result[:item]
    assert_equal "#{@data[:item]}.png", result[:field]
    assert_equal "abc", result[:body]

  end

  def test_build_by_cascade_name_when_cascade_name_dne_raises_error
    assert_raises HT::Builder::BuildError do 
      @builder.run(:dne, @data, :contribute_super)
    end
  end

  def test_build_with_nil_as_cascade_raises_error
    assert_raises HT::Builder::BuildError do 
      @builder.run(nil, @data, :contribute_super)
    end
  end

  def test_stop_build_and_return_with_current_result
    HT::Cascade.new(@cascade_name) do 
      layer :contribute_base do 
        s :player, 1
        halt
      end
    end
    
    expected = {item: @data[:item], image: "#{@data[:player]}.png", player: 1}
    assert_equal expected,  @builder.run(@cascade_name, @data, :contribute_super)
  end

  def test_stop_before_and_return_with_last_layer_result
    HT::Cascade.new(@cascade_name) do 
      layer :contribute_base do 
        s :player, 1
        halt :before
      end

      layer :new_layer, :contribute_base do
        assert false # I should never be run or this test fails
      end
    end
    
    expected = {item: @data[:item], image: "#{@data[:player]}.png"}
    assert_equal expected, @builder.run(@cascade_name, @data, :new_layer)
  end

  def test_stop_after_and_return_with_current_layer_result
    HT::Cascade.new(@cascade_name) do 
      layer :contribute_base do 
        halt :after
        s :player, 1
      end

      layer :new_layer, :contribute_base do
        assert false # I should never be run or this test fails
      end
    end
    
    expected = {item: @data[:item], image: "#{@data[:player]}.png", player: 1}
    assert_equal expected, @builder.run(@cascade_name, @data, :new_layer)
  end

  def test_rollback_and_continue
    HT::Cascade.new(@cascade_name) do 
      layer :contribute_base do 
        s :player, 1
        halt :rollback
      end

      layer :new_layer, :contribute_base do
        s :abc, 2
      end
    end
    
    expected = {item: @data[:item], image: "#{@data[:player]}.png", abc: 2}
    assert_equal expected, @builder.run(@cascade_name, @data, :new_layer)
  end

  def test_continue_command
    HT::Cascade.new(@cascade_name) do 
      layer :contribute_base do 
        s :player, 1
        halt :continue
        s :def, 3
      end

      layer :new_layer, :contribute_base do
        s :abc, 2
      end
    end
    
    expected = {item: @data[:item], image: "#{@data[:player]}.png", player: 1, abc: 2}
    assert_equal expected, @builder.run(@cascade_name, @data, :new_layer)
  end

  def test_unkown_halt_type_raises_error
    HT::Cascade.new(@cascade_name) do 
      base do 
        halt :dne
      end
    end

    assert_raises HT::Builder::BuildError do 
      @builder.run(@cascade_name, @data, :base)
    end
  end

  def test_halt_before_overrides_halt_none
    HT::Cascade.new(@cascade_name) do 
      base do 
        s :a, 1
        halt :before
        s :b, 2
        halt
        s :c, 3
      end
    end

    expected = {}
    assert_equal expected, @builder.run(@cascade_name, @data, :base)
  end

  def test_halt_none_overrides_halt_before
    HT::Cascade.new(@cascade_name) do
      base do 
        s :a, 1
        halt
        s :b, 2
        halt :before
        s :c, 3
      end
    end

    expected = {a: 1}
    assert_equal expected, @builder.run(@cascade_name, @data, :base)
  end

  def test_halt_before_following_halt_after_ovverrides
    HT::Cascade.new(@cascade_name) do 
      base do 
        s :a, 1
        halt :after
        s :b, 2
        halt :before
        s :b, 3
      end
    end
    
    expected = {}
    assert_equal expected, @builder.run(@cascade_name, @data, :base)
  end

  def test_halt_after_following_halt_before_does_not_override
    HT::Cascade.new(@cascade_name) do 
      base do 
        s :a, 1
        halt :before
        s :b, 2
        halt :after
        s :a, 3
      end
    end

    expected = {}
    assert_equal expected, @builder.run(@cascade_name, @data, :base)
  end

  def test_run_raises_build_error_if_not_given_valid_layer
    assert_raises HT::Builder::BuildError do 
      @builder.run(@cascade_name, @data, :dne)
    end
  end

  def test_be_backwards_compat_with_0_dot_0_dot_0
    cascade = HT::Cascade.new(@cascade_name) do |t|
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
