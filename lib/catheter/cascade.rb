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
      @cascade[:base] = block
    end
    
    def layer(opts, &block)
      @cascade[opts[:name]] = {depends: opts[:depends] || [], block: block}
    end
    
    def build(name, opts)
      @result = {}
      
      @cascade[:base].call(self, opts)
      return @result if name == :base
      return @result unless @cascade.has_key?(name)
      
      top = @cascade[name]
      dependencies = top[:depends]
      dependencies.reverse.each do |dependency|
        next unless @cascade.has_key?(dependency) && @cascade[dependency].has_key?(:block)
        @cascade[dependency][:block].call(self, opts)
      end
      
      top[:block].call(self, opts)
      
      @result
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