module HT
  class Cascade

    attr_accessor :name
    attr_reader   :cascade
    
    def [](k)
      @cascade[k]
    end

    def initialize(name = nil, &block)
      self.name = name
      @cascade = {base: nil}
      instance_eval(&block) if block
    end

    # this method should not be used. It is deprected but exists for
    # backwards compatibility with v0.0.0
    def build(layer_name, data)
      Builder.new.run(cascade, data, layer_name)
    end
    
    def base(&block)
      @cascade[:base] = {depends: nil, block: block}
    end
    
    def layer(name, dependency=:base, &block)
      @cascade[name] = {depends: dependency, block: block}
    end

    def has_layer?(name)
      @cascade.has_key?(name)
    end
    alias :has_key? :has_layer? # to allow support for passing hashes in place of 
                                # a real cascade in the build process for testing
    
    def dependency(layer_name)
      (@cascade[layer_name] || {})[:depends]
    end
    
  end
end
