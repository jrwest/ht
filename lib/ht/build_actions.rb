module HT
  module BuildActions
    def halt(type = :none)
      case type
      when :none, :after
        @halt_after = true
      when :before
        @halt_before = true
      when :rollback
        @rollback = true
      else
        raise Builder::BuildError.new("Don't know how to halt #{type}")
      end

      throw :ht_halt if type == :none
    end
  end
end
