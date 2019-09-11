require_relative "helper"

module RubyX
  module Builtin
    class TestWordGet < MiniTest::Test
      include BuiltinHelper
      def source
        <<GET
        class Word
          def get_internal_byte(at)
            X.get_internal_byte
          end
        end
GET
      end
      def test_mom_meth
        assert_equal :get_internal_byte , compiler.callable.name
      end
      def test_instr_len
        assert_equal 7 , compiler.mom_instructions.length
      end
      def test_instr_get
        assert_equal Mom::GetInternalByte , compiler.mom_instructions.next.class
      end
      def test_risc
        assert_equal 41 , compiler.to_risc.risc_instructions.length
      end
    end
  end
end
