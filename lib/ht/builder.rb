require 'ht/template_methods'
require 'ht/build_actions'

module HT
  class Builder
    include TemplateMethods
    include BuildActions

    class BuildError < RuntimeError; end

    attr_reader :data

    def dependency_list(cascade, layer_name)
      if direct_dependency = get_dependency(cascade, layer_name)
        [direct_dependency] + dependency_list(cascade, direct_dependency)
      else 
        []
      end

    end

    def run(cascade, data, layer_name)
      cascade = get_cascade(cascade)
      @result = {}
      @data = data.freeze
      
      dependencies = dependency_list(cascade, layer_name).reverse
      catch :ht_stop do 
        (dependencies + [layer_name]).each do |layer|
          raise BuildError.new("Unkown Layer: #{layer_name}") unless (layer_info = cascade[layer]) && layer_info[:block]
          
          run_layer layer_info, data
        end
      end

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
      
      prepare_run
      
      catch :ht_halt do 
        if block.arity == 2 # support backwards compat. with v0.0.0
          block.call self, data
        else
          instance_exec data, &block
        end
      end

      finalize_run
    end

    def prepare_run
      @layer_result = {}
      @halt = false
      @rollback = false
    end

    def finalize_run
      @result.merge! @layer_result unless rollback_run? # do not merge "rollbacks" 
                                                        # (halt :before is a halting rollback)

      throw :ht_stop if stop_execution? # exit build process if instructed to do so 
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

    def rollback_run?
      @rollback
    end

    def stop_execution?
      @halt
    end

  end
end
