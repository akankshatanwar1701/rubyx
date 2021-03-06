module Risc
  # simulate memory during compile time.
  #
  # Memory comes in chunks, power of 2 chunks actually.
  #
  # Currently typed instance variables map to ruby instance variables and so do not
  # end up in memory. Memory being only for indexed word aligned access.
  #
  # Parfait really does everything else, apart from the internal_get/set
  # And our fake memory (other than hte previously used array, does bound check)
  class FakeMemory
    attr_reader :min , :object
    def initialize(object,from , size)
      @object = object
      @min = from
      @memory = Array.new(size)
      raise "only multiples of 2 !#{size}" unless size == 2**(Math.log2(size).to_i)
    end
    def set(index , value)
      range_check(index)
      _set(index,value)
    end
    alias :[]=  :set
    def _set(index , value)
      @memory[index] = value
      value
    end
    def get(index)
      range_check(index)
      _get(index)
    end
    alias :[] :get

    def _get(index)
      @memory[index]
    end

    def size
      @memory.length
    end

    def range_check(index)
      raise "index too low #{index} < #{min} in #{object.class}" if index < 0
      raise "index too big #{index} >= #{size} #{object.class}" if index >= size
    end
  end
end
