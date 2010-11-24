require 'helper'

CASCADE = HT::Cascade.new(:my_cascade) do |t|
  t.base do |to, opts|
    to.set_value :item, opts[:item]
    to.set_value :image, "#{opts[:player]}.png"
  end
  
  t.layer :contribute_base do |to, opts|
    to.set_value :player, opts[:player]
    to.set_value :image, "#{opts[:item]}.png"
  end
  
  t.layer :contribute_part, :contribute_base do |to, opts|
    to.set_value :body, to.get_value(:image)
  end
  
  t.layer :contribute_part_1, :contribute_base do |to, opts|
    to.set_value :body, "zxy"
    to.set_value :field, "def"
    to.set_value :field2, "123"
  end
  
  t.layer :contribute_super, :contribute_part do |to, opts|
    to.set_value :field, to.get_value(:image)
    to.set_value :body, "abc"
  end
  
end

OPTS = {:player => "jordanrw", :item => "cool-thing"}

class TestHT < MiniTest::Unit::TestCase
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
    result = CASCADE.build(:contribute_super, OPTS)
    
    assert_equal OPTS[:player], result[:player]
    assert_equal OPTS[:item], result[:item]
    assert_equal "#{OPTS[:item]}.png", result[:field]
    assert_equal "abc", result[:body]
  end
 
  def test_three_layers
    
  end
  
    
   def test_build_dependency_list_base_case
     cascade = {base: {depends: nil, block: nil}}
     
     assert_equal [], CASCADE.build_dependency_list(:base, cascade)
   end
   
   def test_build_dependency_base_case_when_layers_exist
     cascade = {base: {depends: nil, block: nil}, contribute_base: {depends: :base, block: nil}}
     
     assert_equal [], CASCADE.build_dependency_list(:base, cascade)
   end
   
  
   def test_build_dependency_one_layer_up
     cascade = {base: {depends: nil, block: nil}, 
                contribute_base: {depends: :base, block: nil}}
                
     assert_equal [:base], CASCADE.build_dependency_list(:contribute_base, cascade)
   end
   
   def test_build_dependency_two_layers_up
     cascade = {base: {depends: nil, block: nil}, 
                contribute_base: {depends: :base, block: nil},
                contribute_part: {depends: :contribute_base, block: nil}}
     
     assert_equal [:contribute_base, :base] , CASCADE.build_dependency_list(:contribute_part, cascade)
   end
   
   def test_build_dependency_three_layers_up
     cascade = {base: {depends: nil, block: nil}, 
                contribute_base: {depends: :base, block: nil},
                contribute_part: {depends: :contribute_base, block: nil},
                contribute_part_2: {depends: :contribute_part, block: nil}}
                
     assert_equal [:contribute_part, :contribute_base, :base] , CASCADE.build_dependency_list(:contribute_part_2, cascade)
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
     
     
     assert_equal [], CASCADE.build_dependency_list(:base, cascade)
     assert_equal [:contribute_part_2, :contribute_part, :contribute_base, :base], CASCADE.build_dependency_list(:contribute_part_3, cascade)
     assert_equal expected, CASCADE.build_dependency_list(:contribute_part_5, cascade)
   end
   # 
   # 
   # def test_build_dependency_two_layers_two_branches
   #   cascade = {base: {depends: nil, block: nil},
   #              contribute_base_1: {depends: [:base], block:nil},
   #              contribute_base_2: {depends: [:base], block:nil},
   #              contribute_part_1: {depends: [:contribute_base_1, :contribute_base_2]}}
   # 
   # 
   #   assert_equal [:contribute_base_1, :contribute_base_2, :base], CASCADE.build_dependency_list(:contribute_part_1, cascade)
   #   
   #   cascade = {base: {depends: nil, block: nil},
   #              contribute_base_1: {depends: [:base], block:nil},
   #              contribute_base_2: {depends: [:base], block:nil},
   #              contribute_part_1: {depends: [:contribute_base_2, :contribute_base_1]}}
   #              
   #   assert_equal [:contribute_base_2, :contribute_base_1, :base], CASCADE.build_dependency_list(:contribute_part_1, cascade)
   # end
   # 
   # def test_build_dependency_two_layers_three_branches
   #   cascade = {base: {depends: nil, block: nil},
   #              contribute_base_1: {depends: [:base], block:nil},
   #              contribute_base_2: {depends: [:base], block:nil},
   #              contribute_base_3: {depends: [:base], block:nil},
   #              contribute_part_1: {depends: [:contribute_base_1, :contribute_base_2]}, 
   #              contribute_part_2: {depends: [:contribute_base_3, :contribute_base_1, :contribute_base_2]}}
   #              
   #   assert_equal [:contribute_base_1, :contribute_base_2, :base], CASCADE.build_dependency_list(:contribute_part_1, cascade)
   #   assert_equal [:contribute_base_3, :contribute_base_1, :contribute_base_2, :base], CASCADE.build_dependency_list(:contribute_part_2, cascade) 
   #   
   # end
   # 
   # def test_build_dependency_three_layers_5_branches
   #   cascade = {base: {depends: nil, block: nil},
   #              contribute_base_1: {depends: [:base], block:nil},
   #              contribute_base_2: {depends: [:base], block:nil},
   #              contribute_base_3: {depends: [:base], block:nil},
   #              contribute_part_1: {depends: [:contribute_base_1, :contribute_base_2]}, 
   #              contribute_part_2: {depends: [:contribute_base_3, :contribute_base_1, :contribute_base_2]},
   #              contribute_top: {depends: [:contribute_part_1, :contribute_part_2], block: nil}}
   #              
   #    
   #   
   #   expected = [:contribute_part_1, :contribute_part_2, :contribute_base_1, :contribute_base_2, :contribute_base_3, :base]         
   #   assert_equal [:contribute_base_1, :contribute_base_2, :base], CASCADE.build_dependency_list(:contribute_part_1, cascade)
   #   assert_equal [:contribute_base_3, :contribute_base_1, :contribute_base_2, :base], CASCADE.build_dependency_list(:contribute_part_2, cascade) 
   #   assert_equal expected, CASCADE.build_dependency_list(:contribute_top, cascade) 
   # end
   # 
   # def test_build_dependency_medium_test
   #   cascade = {base: {depends: nil, block: nil},
   #              contribute_base_1: {depends: [:base]},
   #              contribute_base_2: {depends: [:base]},
   #              contribute_interim: {depends: [:contribute_base_1]},
   #              contribute_part_1: {depends: [:contribute_interim]},
   #              contribute_part_2: {depends: [:contribute_base_2, :contribute_base_1]},
   #              contribute_part_3: {depends: [:contribute_part_1]},
   #              contribute_part_4: {depends: [:contribute_part_2]},
   #              contribute_all: {depends: [:contribute_part_3, :contribute_part_4]}}
   #    
   #   #expected [:contribute_part_4, :contribute_part_2, :contribute_base_2, :contribute_part_3, :contribute_part_1, :contribute_interim, :contribute_base_1, :base]
   #   #expected [:contribute_part_3, :contribute_part_1, :contribute_interim, :contribute_base_1, :contribute_part_4, :contribute_part_2, :contribute_base_2, :base]
   #   #expected =  [:contribute_part_3, :contribute_part_4, :contribute_part_1, :contribute_part_2, :contribute_interim, :contribute_base_2, :contribute_base_1, :base]
   #   #expected = [:contribute_part_3, :contribute_part_4, :contribute_part_1, :contribute_part_2, :contribute_interim, :contribute_base_1, :contribute_base_2, :base]
   #   assert_equal expected, CASCADE.build_dependency_list(:contribute_all, cascade) 
   # 
   # end
end
