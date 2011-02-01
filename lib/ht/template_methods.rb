module HT
  module TemplateMethods
    def set_value(k, v)
      return unless @layer_result
      
      @layer_result[k] = v
    end
    alias :set :set_value
    alias :s :set_value
    
    def get_value(k)
      return @layer_result[k] if @layer_result && @layer_result.has_key?(k)
      @result[k] if @result
    end
    alias :get :get_value
    alias :g :get_value
  end
end
