module HT
  class Builder

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
        cascade[dependency][:block].call(self, data)
      end
      
      top[:block].call(self, data)
      
      @result
    end

    def set_value(k, v)
      return unless @result
      
      @result[k] = v
    end
    
    def get_value(k)
      @result[k] if @result
    end

    private

    def get_dependency(cascade, layer_name)
      # conditional is to allow hashes in testing
      cascade.respond_to?(:dependency) ? cascade.dependency(layer_name) : cascade[layer_name][:depends]
    end
  end
end
