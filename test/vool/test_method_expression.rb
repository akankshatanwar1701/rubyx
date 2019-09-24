require_relative "helper"

module Vool
  class TestMethodExpression < MiniTest::Test
    include VoolCompile

    def setup
      Parfait.boot!(Parfait.default_test_options)
      ruby_tree = Ruby::RubyCompiler.compile( as_main("a = 5") )
      @clazz = ruby_tree.to_vool
    end
    def method
      @clazz.body.first
    end
    def test_setup
      assert_equal ClassExpression , @clazz.class
      assert_equal Statements , @clazz.body.class
      assert_equal MethodExpression , method.class
    end
    def test_fail
      assert_raises{ method.to_parfait }
    end
    def test_method
      clazz = @clazz.to_parfait
      assert_equal Parfait::Class , clazz.class
      meth = method.to_parfait(clazz)
      assert_equal Parfait::VoolMethod , meth.class
      assert_equal :main , meth.name
    end
    def test_is_instance_method
      assert main = @clazz.to_parfait.get_instance_method(:main)
    end

  end
end
