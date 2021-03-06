require "util/list"

module Risc

  # the register machine has at least 8 registers, named r0-r5 , :lr and :pc
  # (for historical reasons , r for register, pc for ProgramCounter ie next instruction address
  # and lr means LinkRegister, ie the location where to return to when in a function)
  #
  # We can load and store their contents, move data between them and
  #   access (get/set) memory at a constant offset from a register
  # While SlotMachine works with objects, the register machine has registers,
  #             but we keep the names for better understanding, r2-5 are temporary/scratch
  # There is no direct memory access, only through registers
  # Constants can/must be loaded into registers before use

  # At compile time, Instructions form a linked list (:next attribute is the link)
  # At run time Instructions are traversesed as a graph
  #
  # Branches fan out, Labels collect
  # Labels are the only valid branch targets
  #
  class Instruction
    include Util::List

    def initialize( source , nekst = nil )
      @source = source
      @next = nekst
      return unless source
      raise "Source must be string or Instruction, not #{source.class}" unless source.is_a?(String) or
                source.is_a?(SlotMachine::Instruction) or source.is_a?(Parfait::Callable)
    end
    attr_reader :source

    def to_arr
      ret  = []
      self.each {|ins| ret << ins}
      ret
    end

    # just part of the protocol, noop in this case
    def precheck
    end

    # return an array of names of registers that is used by the instruction
    def register_attributes
      raise "Not implemented in #{self.class}"
    end

    # return an array of names of registers that is used by the instruction
    def register_names
      register_attributes.collect {|attr| get_register(attr)}
    end

    # get the register value that has the name (ie attribute by that name)
    # return the registers name ie RegisterValue's symbol
    def get_register(name)
      instance_variable_get("@#{name}".to_sym).symbol
    end

    # set all registers that has the name "name"
    # going through the register_names and setting all where the
    # get_register would return name
    # Create new RegisterValue with new name and swap the variable out
    def set_registers(name , value)
      register_attributes.each do |attr|
        reg = instance_variable_get("@#{attr}".to_sym)
        next unless reg.symbol == name
        new_reg = reg.dup(value)
        instance_variable_set("@#{attr}".to_sym , new_reg)
      end
    end

    def to_cpu( translator )
      translator.translate( self )
    end

    def class_source( derived)
      "#{self.class.name.split("::").last}: #{derived} #{source_mini}"
    end
    def source_mini
      return "(no source)" unless source
      return "(from: #{source[0..50]})" if source.is_a?(String)
      "(from: #{source.class.name.split("::").last})"
    end
  end

end

require_relative "setter"
require_relative "getter"
require_relative "reg_to_slot"
require_relative "slot_to_reg"
require_relative "reg_to_byte"
require_relative "byte_to_reg"
require_relative "load_constant"
require_relative "load_data"
require_relative "syscall"
require_relative "function_call"
require_relative "function_return"
require_relative "transfer"
require_relative "label"
require_relative "branch"
require_relative "dynamic_jump"
require_relative "operator_instruction"
