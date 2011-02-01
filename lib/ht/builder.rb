require 'ht/template_methods'
module HT
  class Builder
    include TemplateMethods

    def dependency_list(cascade, layer_name)
      if direct_dependency = get_dependency(cascade, layer_name)
        [direct_dependency] + dependency_list(cascade, direct_dependency)
      else 
        []
      end

    end

    def run(cascade, data, name)
      @result = {}
      
      top = cascade[name]
      dependencies = dependency_list(cascade, name).reverse
      dependencies.each do |dependency|
        next unless cascade.has_key?(dependency) && cascade[dependency].has_key?(:block)
        instance_exec data, &cascade[dependency][:block]
      end
      
      instance_exec(data, &top[:block]) if top[:block]

      @result
    end

    private

    def get_dependency(cascade, layer_name)
      # conditional is to allow hashes in testing
      cascade.respond_to?(:dependency) ? cascade.dependency(layer_name) : cascade[layer_name][:depends]
    end
  end
end
