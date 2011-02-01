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
    cascade = HT::Cascade.new(@cascade_name)
    cascade.base &@block
    
    assert !cascade.cascade[:base][:depends]
    assert_equal @block, cascade.cascade[:base][:block]
  end

  def test_create_base_inblock
    block = @block
    cascade = HT::Cascade.new(@cascade_name) do
      base &block
    end

    assert_equal @block, cascade.cascade[:base][:block]
  end

  def test_create_layer_no_dependency
    cascade = HT::Cascade.new(@cascade_name)
    cascade.layer :my_layer, &@block

    assert_equal :base, cascade.cascade[:my_layer][:depends]
    assert_equal @block, cascade.cascade[:my_layer][:block]
  end

  def test_create_layer_with_existing_dependency
    block2 = ->(res, data) {}
    cascade = HT::Cascade.new(@cascade_name) do
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
