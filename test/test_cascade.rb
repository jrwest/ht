require 'helper'

class TestCascade < MiniTest::Unit::TestCase
  def setup
    @cascade_name = :test_cascade
    @block = ->(data) do 
      # code in here doesn't matter
    end
  end

  def test_cascade_has_no_name_if_not_given
    cascade = HT::Cascade.new

    assert_nil cascade.name
  end

  def test_cascade_has_name_if_given
    cascade = HT::Cascade.new(@cascade_name)

    assert_equal @cascade_name, cascade.name
  end

  def test_create_base
    cascade = HT::Cascade.new
    cascade.base &@block
    
    assert !cascade.cascade[:base][:depends]
    assert_equal @block, cascade.cascade[:base][:block]
  end

  def test_create_base_inblock
    block = @block
    cascade = HT::Cascade.new do
      base &block
    end

    assert_equal @block, cascade.cascade[:base][:block]
  end

  def test_create_layer_no_dependency
    cascade = HT::Cascade.new
    cascade.layer :my_layer, &@block

    assert_equal :base, cascade.cascade[:my_layer][:depends]
    assert_equal @block, cascade.cascade[:my_layer][:block]
  end

  def test_create_layer_with_existing_dependency
    block2 = ->(res, data) {}
    cascade = HT::Cascade.new do
      layer :first_layer, &@block
      layer :second_layer, :first_layer, &block2
    end

    assert_equal :first_layer, cascade.cascade[:second_layer][:depends]
    assert_equal block2, cascade.cascade[:second_layer][:block]
  end

  def test_create_layer_fails_with_nonexisting_dependency
    block = @block
    assert_raises HT::Cascade::InvalidDependency do 
      HT::Cascade.new do 
        base &block
        layer :some_layer, :dne, &block
      end
    end
  end

  def test_create_layer_fails_with_circular_dependency
    block = @block
    assert_raises HT::Cascade::InvalidDependency do
      HT::Cascade.new do 
        base  &block
        layer :layer_1, :layer_1, &block
      end
    end
  end

  # if this test errors it fails and is why it
  # has no assertions
  def test_create_layer_aloud_with_no_base
    block = @block
    HT::Cascade.new do 
      layer :layer_1, &block
    end
  end

  def test_cascade_name_registered_if_given
    assert_nil HT::Cascade[:abc]
    cascade = HT::Cascade.new(:abc)
    assert_equal cascade, HT::Cascade[:abc]
  end

  def test_cascade_list_flush
    cascade = HT::Cascade.new(:def)
    assert_equal cascade, HT::Cascade[:def]
    HT::Cascade.flush_global
    assert_nil HT::Cascade[:def]
  end

  def test_reopen_cascade_with_no_changes
    block = ->() {}
    HT::Cascade.new(:def) do 
      base &block
      layer :layer_1, &block
    end
    HT::Cascade.new(:def)
    
    assert_equal block, HT::Cascade[:def].cascade[:base][:block]
    assert_equal block, HT::Cascade[:def].cascade[:layer_1][:block]
  end

  def test_reopen_cascade_updates_base_block
    block1 = ->() { 1 }
    block2 = ->() { 2 }
    HT::Cascade.new(:def) do 
      base &block1
    end
    HT::Cascade.new(:def) do 
      base &block2
    end

    assert_equal block2, HT::Cascade[:def].cascade[:base][:block]
  end

  def test_reopen_cascade_updates_layer_block
    block1 = ->() { 1 }
    block2 = ->() { 2 }
    HT::Cascade.new(:def) do 
      layer :layer_1, &block1
    end
    HT::Cascade.new(:def) do 
      layer :layer_1, &block2
    end

    assert_equal block2, HT::Cascade[:def].cascade[:layer_1][:block]
  end

  def test_reopen_cascade_updates_layer_dependency
    block = @block
    HT::Cascade.new(:def) do 
      layer :layer, &block
      layer :middle, :layer, &block
      layer :top, :layer, &block
    end
    HT::Cascade.new(:def) do 
      layer :top, :middle, &block
    end

    assert_equal :middle, HT::Cascade[:def].cascade[:top][:depends]
  end

  def test_reopen_cascade_can_create_new_layers
    block = @block
    HT::Cascade.new(:def)
    HT::Cascade.new(:def) do 
      base &block
      layer :layer, &block
    end

    assert_equal block, HT::Cascade[:def].cascade[:base][:block]
    assert_equal block, HT::Cascade[:def].cascade[:layer][:block]
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

    assert_equal 1, cascade.build(:path_share, {a: 1, b: 2})[:a]
  end
end
