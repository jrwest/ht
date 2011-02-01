require 'helper'

class TestCascade < MiniTest::Unit::TestCase
  def setup
    @cascade_name = :test_cascade
    @block = ->(res, data) do 
      # code in here doesn't matter
    end
  end

  def test_cascade_has_name
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
    skip "Not Implemented"
  end

  def test_create_layer_fails_with_circular_dependency
    skip "Not Implemented"
  end
end
