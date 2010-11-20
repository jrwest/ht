module Catheter
  class Cascade
    attr_accessor :name
    attr_reader   :cascade
    
    def initialize(name)
      self.name = name
      @cascade = {base: nil}
      if block_given?
        yield(self)
      end
    end
    
    def base(&block)
      @cascade[:base] = {depends: nil, block: block}
    end
    
    def layer(name, dependency=:base, &block)
      @cascade[name] = {depends: dependency, block: block}
    end

    def build(name, opts)
      @result = {}
      
      top = @cascade[name]
      dependency_list = build_dependency_list(name).reverse
      dependency_list.each do |dependency|
        next unless @cascade.has_key?(dependency) && @cascade[dependency].has_key?(:block)
        @cascade[dependency][:block].call(self, opts)
      end
      
      top[:block].call(self, opts)
      
      @result
    end
    
    def build_dependency_list(name, cascade = @cascade)
      if direct_dependency = cascade[name][:depends]
        [direct_dependency] + build_dependency_list(direct_dependency, cascade)
      else 
        []
      end
    end
    
    def get_direct_dependencies(name, cascade)
      (cascade[name] || {})[:depends] || []
    end
        
    def set_value(k, v)
      return unless @result
      
      @result[k] = v
    end
    
    def get_value(k)
      @result[k] if @result
    end
  end
end