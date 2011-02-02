module HT
  module BuildActions
    def halt(type = :none)
      case type
      when :none, :after
        @halt = true
        @rollback = false
      when :before
        @halt = true
        @rollback = true
      when :rollback
        @rollback = true
        @halt = false
      when :continue
        @rollback = false
        @halt = false
      else
        raise Builder::BuildError.new("Don't know how to halt #{type}")
      end

      throw :ht_halt if [:none, :before, :continue, :rollback].include?(type)
    end
  end
end
