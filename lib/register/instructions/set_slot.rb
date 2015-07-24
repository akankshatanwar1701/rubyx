module Register

  # SetSlot moves data into memory from a register.
  # GetSlot moves data into a register from memory.
  # Both use a base memory (a register)

  # While the virtual machine has only one instruction (Set) to move data between slots,
  # the register has two, namely GetSlot and SetSlot
  #
  # This is because that is what cpu's can do. In programming terms this would be accessing
  #  an element in an array, in the case of SetSlot setting the register in the array.

  # btw: to move data between registers, use RegisterTransfer

  class SetSlot < Instruction

    # If you had a c array and index offset
    # the instruction would do array[index] = register
    # So SetSlot means the register (first argument) moves to the slot (array and index)
    def initialize register , array , index
      @register = register
      @array = array
      @index = index
      raise "not integer #{index}" unless index.is_a? Numeric
      raise "Not register #{register}" unless Register::RegisterReference.look_like_reg(register)
      raise "Not register #{array}" unless Register::RegisterReference.look_like_reg(array)
    end
    attr_accessor :register , :array , :index
    def to_s
      "SetSlot(#{register}: #{array}[#{index}])"
    end

  end

  # Produce a SetSlot instruction.
  # From and to are registers or symbols that can be transformed to a register by resolve_to_register
  # index resolves with resolve_index.
  def self.set_slot from , to , index
    index = resolve_index( to , index)
    from = resolve_to_register from
    to = resolve_to_register to
    SetSlot.new( from , to , index)
  end

end
