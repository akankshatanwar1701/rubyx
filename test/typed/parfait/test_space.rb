require_relative "../helper"

class TestSpace < MiniTest::Test

  def setup
    @machine = Register.machine.boot
    @space = Parfait.object_space
  end
  def classes
    [:Kernel,:Word,:List,:Message,:NamedList,:Type,:Object,:Class,:Dictionary,:TypedMethod , :Integer]
  end
  def test_booted
    assert_equal true , @machine.booted
  end

  def test_global_space
    assert_equal Parfait::Space , Parfait.object_space.class
  end
  def test_integer
    int = Parfait.object_space.get_class_by_name :Integer
    assert_equal 3, int.instance_type.method_names.get_length
  end

  def test_classes_class
    classes.each do |name|
      assert_equal :Class , @space.classes[name].get_class.name
      assert_equal Parfait::Class , @space.classes[name].class
    end
  end

  def test_types
    assert  @space.types.is_a? Parfait::Dictionary
  end

  def test_types_each
    @space.each_type do |type|
      assert type.is_a?(Parfait::Type)
    end
  end

  def test_classes_type
    classes.each do |name|
      assert_equal Parfait::Type , @space.classes[name].get_type.class
    end
  end

  def test_classes_name
    classes.each do |name|
      assert_equal name , @space.classes[name].name
    end
  end

  def test_method_name
    classes.each do |name|
      cl = @space.classes[name]
      cl.method_names.each do |mname|
        method = cl.get_instance_method(mname)
        assert_equal mname , method.name
        assert_equal name , method.for_class.name
      end
    end
  end
  def test_messages
    mess = @space.first_message
    all = []
    while mess
      all << mess
      assert mess.locals
      mess = mess.next_message
    end
    assert_equal all.length , all.uniq.length
    # there is a 5.times in space, but one Message gets created before
    assert_equal  50 + 1 , all.length
  end
  def test_message_vars
    mess = @space.first_message
    all = mess.get_instance_variables
    assert all
    assert all.include?(:next_message)
  end

  def test_create_class
    assert @space.create_class( :NewClass )
  end

  def test_created_class_is_stored
    @space.create_class( :NewerClass )
    assert @space.get_class_by_name(:NewerClass)
  end

end
