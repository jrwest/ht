require 'ht/template_methods'
module HT
  class Builder
    include TemplateMethods

    attr_reader :data

    def dependency_list(cascade, layer_name)
      if direct_dependency = get_dependency(cascade, layer_name)
        [direct_dependency] + dependency_list(cascade, direct_dependency)
      else 
        []
      end

    end

    def run(cascade, data, name)
      @result = {}
      @data = data

      top = cascade[name]
      dependencies = dependency_list(cascade, name).reverse
      dependencies.each do |dependency|
        next unless cascade.has_key?(dependency) && cascade[dependency].has_key?(:block)
        run_layer cascade[dependency], data
#        instance_exec data, &cascade[dependency][:block]
      end
      
#      instance_exec(data, &top[:block]) if top[:block]
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
  end
end
