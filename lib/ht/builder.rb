require 'ht/template_methods'
module HT
  class Builder
    include TemplateMethods

    class BuildError < RuntimeError; end

    attr_reader :data

    def dependency_list(cascade, layer_name)
      if direct_dependency = get_dependency(cascade, layer_name)
        [direct_dependency] + dependency_list(cascade, direct_dependency)
      else 
        []
      end

    end

    def run(cascade, data, name)
      cascade = get_cascade(cascade)
      @result = {}
      @data = data.freeze

      top = cascade[name]
      dependencies = dependency_list(cascade, name).reverse
      dependencies.each do |dependency|
        next unless cascade.has_key?(dependency) && cascade[dependency].has_key?(:block)
        run_layer cascade[dependency], data
      end
      
      run_layer top, data

      @data = nil
      @result
    end

    private

    def get_dependency(cascade, layer_name)
      # conditional is to allow hashes in testing
      cascade.respond_to?(:dependency) ? cascade.dependency(layer_name) : cascade[layer_name][:depends]
    end

    def run_layer(layer, data)
      block = layer[:block]
      return unless block

      if block.arity == 2 # support backwards compat. with v0.0.0
        block.call self, data
      else
        instance_exec data, &block
      end
    end
    
    def get_cascade(cascade)
      res = case cascade
      when Cascade
        cascade
      else
        Cascade[cascade]
      end

      res.nil? ? raise(BuildError.new("Invalid Cascade")) : res
    end

  end
end
