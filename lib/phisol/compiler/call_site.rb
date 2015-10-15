module Phisol
  Compiler.class_eval do

    def on_call statement
      name , arguments , receiver = *statement
      name = name.to_a.first
      raise "not inside method " unless @method
      reset_regs
      if receiver
        me = process( receiver.to_a.first  )
      else
        me = Register.self_reg @method.for_class.name
      end
      #move the new message (that we need to populate to make a call) to std register
      new_message = Register.resolve_to_register(:new_message)
      @method.source.add_code Register.get_slot(@method, :message , :next_message , new_message )
      # move our receiver there
      @method.source.add_code Register.set_slot( statement , me , :new_message , :receiver)
      # load method name and set to new message (for exceptions/debug)
      name_tmp = use_reg(:Word)
      @method.source.add_code Register::LoadConstant.new(statement, name , name_tmp)
      @method.source.add_code Register.set_slot( statement , name_tmp , :new_message , :name)
      # next arguments. reset tmp regs for each and load result into new_message
      arguments.to_a.each_with_index do |arg , i|
        reset_regs
        # processing should return the register with the value
        val = process( arg)
        raise "Not register #{val}" unless val.is_a?(Register::RegisterValue)
        # which we load int the new_message at the argument's index
        @method.source.add_code Register.set_slot( statement , val , :new_message , i + 1)
      end

      # now we have to resolve the method name (+ receiver) into a callable method
      method = nil
      if(me.value)
        raise "branch should only be optiisation, revit"
        me = me.value
        if( me.is_a? Parfait::Class )
          raise "unimplemented #{code}  me is #{me}"
        elsif( me.is_a? Symbol )
          # get the function from my class. easy peasy
          method = Virtual.machine.space.get_class_by_name(:Word).get_instance_method(name)
          raise "Method not implemented #{me.class}.#{code.name}" unless method
          @method.source.add_code Virtual::MethodCall.new( method )
        elsif( me.is_a? Fixnum )
          method = Virtual.machine.space.get_class_by_name(:Integer).get_instance_method(name)
          #puts Virtual.machine.space.get_class_by_name(:Integer).method_names.to_a
          raise "Method not implemented Integer.#{name}" unless method
          @method.source.add_code Virtual::MethodCall.new( method )
        else
          raise "unimplemented: \n#{code} \nfor #{ref.inspect}"
        end
      else
        clazz =  Virtual.machine.space.get_class_by_name(me.type)
        raise "No such class #{me.type}" unless clazz
        method = clazz.get_instance_method(name)
        puts Virtual.machine.space.get_class_by_name(:Integer).method_names.to_a
        raise "Method not implemented Integer.#{name}" unless method
        @method.source.add_code Virtual::MethodCall.new( method )
      end
      raise "Method not implemented #{me.value}.#{name}" unless method
      ret = use_reg( method.source.return_type )
      # the effect of the method is that the NewMessage Return slot will be filled, return it
      # but move it into a register too
      @method.source.add_code Register.get_slot(@method, :message , :return_value , ret )
      ret
    end
  end
end