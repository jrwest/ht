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
  
  t.layer name: :contribute_all, depends: [:contribute_part] do |t, opts|
    t.set_value :body, "abc"
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
  
  def test_layer_that_depend_on_layer_that_depend_on_layer
    result = CASCADE.build(:contribute_all, OPTS)
    
    assert_equal "abc", result[:body]
    assert_equal OPTS[:player], result[:player]
    assert_equal "#{OPTS[:item]}.png", result[:image]
  end
  
  def test_layers_that_depend_on_layers_with_different_paths
    flunk
  end
  
  def test_build_dependency_case_base_case
    cascade = {base: {depends: nil}, block: nil}
    
    assert_equal [], CASCADE.build_dependency_list(:base, cascade)
  end
  
  def test_build_dependency_base_case_when_layers_exist
    cascade = {base: {depends: nil}, block: nil, contribute_base: {depends: [:base], block: nil}}
    
    assert_equal [], CASCADE.build_dependency_list(:base, cascade)
  end
  
  def test_build_dependency_one_layer_up
    cascade = {base: {depends: nil}, block: nil, 
               contribute_base: {depends: [:base], block: nil}}
               
    assert_equal [:base], CASCADE.build_dependency_list(:contribute_base, cascade)
  end
  
  def test_build_dependency_two_layers_up
    cascade = {base: {depends: nil}, block: nil, 
               contribute_base: {depends: [:base], block: nil},
               contribute_part: {depends: [:contribute_base], block: nil}}
    
    assert_equal [:contribute_base, :base] , CASCADE.build_dependency_list(:contribute_part, cascade)
  end
  
  def test_build_dependency_three_layers_up
    cascade = {base: {depends: nil}, block: nil, 
               contribute_base: {depends: [:base], block: nil},
               contribute_part: {depends: [:contribute_base], block: nil},
               contribute_part_2: {depends: [:contribute_part], block: nil}}
               
    assert_equal [:contribute_part, :contribute_base, :base] , CASCADE.build_dependency_list(:contribute_part_2, cascade)
  end
  
  def test_build_dependency_six_layers_up
    cascade = {base: {depends: nil}, block: nil, 
               contribute_base: {depends: [:base], block: nil},
               contribute_part: {depends: [:contribute_base], block: nil},
               contribute_part_2: {depends: [:contribute_part], block: nil}, 
               contribute_part_3: {depends: [:contribute_part_2], block: nil},
               contribute_part_4: {depends: [:contribute_part_3], block: nil},
               contribute_part_5: {depends: [:contribute_part_4], block: nil}}
    
    expected = [:contribute_part_4, :contribute_part_3, :contribute_part_2, :contribute_part, :contribute_base, :base]
    
    
    assert_equal [], CASCADE.build_dependency_list(:base, cascade)
    assert_equal [:contribute_part_2, :contribute_part, :contribute_base, :base], CASCADE.build_dependency_list(:contribute_part_3, cascade)
    assert_equal expected, CASCADE.build_dependency_list(:contribute_part_5, cascade)
  end
end
