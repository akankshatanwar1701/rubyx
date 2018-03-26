require_relative "helper"

module Risc
  class InterpreterReturn < MiniTest::Test
    include Ticker

    def setup
      @string_input = as_main("return 5")
      super
    end

    def test_chain
      #show_ticks # get output of what is
      check_chain [Branch, Label, LoadConstant, SlotToReg, LoadConstant,
             SlotToReg, SlotToReg, RegToSlot, LoadConstant, SlotToReg,
             SlotToReg, SlotToReg, SlotToReg, RegToSlot, LoadConstant,
             SlotToReg, SlotToReg, SlotToReg, SlotToReg, RegToSlot,
             SlotToReg, RegToSlot, LoadConstant, RegToSlot, FunctionCall,
             Label, LoadConstant, RegToSlot, SlotToReg, SlotToReg,
             RegToSlot, SlotToReg, SlotToReg, FunctionReturn, Transfer,
             Syscall, NilClass]
      assert_equal 5 , get_return
    end

    def test_call_main
      call_ins = ticks(25)
      assert_equal FunctionCall , call_ins.class
      assert  :main , call_ins.method.name
    end
    def test_label_main
      call_ins = ticks(26)
      assert_equal Label , call_ins.class
      assert  :main , call_ins.name
    end
    def test_load_5
      load_ins = ticks 27
      assert_equal LoadConstant ,  load_ins.class
      assert_equal 5 , @interpreter.get_register(load_ins.register)
    end
    def test_transfer
      transfer = ticks(35)
      assert_equal Transfer ,  transfer.class
    end
    def test_sys
      sys = ticks(36)
      assert_equal Syscall ,  sys.class
    end
    def test_return
      ret = ticks(34)
      assert_equal FunctionReturn ,  ret.class
      link = @interpreter.get_register( ret.register )
      assert_equal Label , link.class
    end
  end
end