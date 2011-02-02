module HT
  class Cascade

    class InvalidDependency < ArgumentError; end
    
    BARE_LAYER = ->(*args) { }

    attr_accessor :name
    attr_reader   :cascade
    
    def self.[](k)
      @cascades ||= {}
      @cascades[k.to_s]
    end

    def self.add_global(name, instance)
      @cascades ||= {}
      @cascades[name.to_s] = instance
    end

    def self.flush_global
      @cascades = {}
    end

    def [](k)
      @cascade[k]
    end

    def initialize(name = nil, &block)
      self.name = name
      if the_cascade = self.class[name]
        @cascade = the_cascade.cascade
      else
      @cascade = {base: {depends: nil, block: BARE_LAYER}} 
      end
      register(name)
      instance_eval(&block) if block
    end

    # this method should not be used. It is deprected but exists for
    # backwards compatibility with v0.0.0
    def build(layer_name, data)
      Builder.new.run(self, data, layer_name)
    end
    
    def base(&block)
      @cascade[:base] = {depends: nil, block: block}
    end
    
    def layer(name, dependency=:base, &block)
      raise HT::Cascade::InvalidDependency.new("Circular Dependency") if name == dependency
      raise HT::Cascade::InvalidDependency.new("Dependency D.N.E") unless @cascade[dependency]

      if @cascade[name]
        @cascade[name][:depends] = dependency if dependency
        @cascade[name][:block] = block if block
      else
        @cascade[name] = {depends: dependency, block: block}
      end
    end

    def has_layer?(layer_name)
      @cascade.has_key?(layer_name)
    end
    alias :has_key? :has_layer? # to allow support for passing hashes in place of 
                                # a real cascade in the build process for testing
    
    def delete_layer(layer_name)
      @cascade.delete(layer_name)
    end

    def dependency(layer_name)
      (@cascade[layer_name] || {})[:depends]
    end
    
    private

    def register(name)
      return unless name
      self.class.add_global(name, self)
    end

  end
end
