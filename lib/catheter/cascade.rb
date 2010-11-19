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
    
    def layer(opts, &block)
      depends = (opts[:depends] && opts[:depends].size > 0) ? opts[:depends] : [:base]
      @cascade[opts[:name]] = {depends: depends, block: block}
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
      #direct_dependencies = cascade[name][:depends] +  ? cascade[name][:depends] : []
      if direct_dependencies = cascade[name][:depends]
        (direct_dependencies + direct_dependencies.inject([]) do |deps, direct|
          dependency_deps = build_dependency_list(direct, cascade)
          dependency_deps -= [:base] unless direct == direct_dependencies.last
          deps + dependency_deps
        end).uniq
      else
        []
      end
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