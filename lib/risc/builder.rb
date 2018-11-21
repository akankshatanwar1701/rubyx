module Risc

  # A Builder is used to generate code, either by using it's api, or dsl
  #
  # The code is added to the method_compiler.
  #
  class Builder

    attr_reader :built , :compiler

    # pass a compiler, to which instruction are added (usually)
    # second arg determines weather instructions are added (default true)
    # call build with a block to build
    def initialize(compiler, for_source)
      raise "no compiler" unless compiler
      @compiler = compiler
      @source = for_source
      @source_used = false
      @names = {}
    end

    # make the magic: convert incoming names into registers that have the
    # type set according to the name (using resolve_type)
    # names are stored, so subsequent calls use the same register
    def method_missing(name , *args)
      super if args.length != 0
      name = name.to_s
      return @names[name] if @names.has_key?(name)
      if name == "message"
        return Risc.message_reg.set_builder(self)
      end
      if name.index("label")
        reg = Risc.label( @source , "#{name}_#{object_id}")
        @source_used = true
      else
        last_char = name[-1]
        name = name[0 ... -1]
        if last_char == "!" or last_char == "?"
          if @names.has_key?(name)
            return @names[name] if last_char == "?"
            raise "Name exists before creating it #{name}#{last_char}"
          end
        else
          raise "Must create (with ! or ?) before using #{name}#{last_char}"
        end
        type = infer_type(name )
        reg = @compiler.use_reg( type.object_class.name ).set_builder(self)
      end
      @names[name] = reg
      reg
    end

    # Infer the type from a symbol. In the simplest case the sybbol is the class name.
    # But in building, sometimes variations are needed, so next_message or caller work
    # too (and both return "Message")
    # A general "_reg"/"_obj"/"_const" or "_tmp" at the end of the name will be removed
    # An error is raised if the symbol/object can not be inferred
    def infer_type( name )
      as_string = name.to_s
      parts = as_string.split("_")
      if( ["reg" , "obj" , "tmp" , "self" , "const", "1" , "2"].include?( parts.last ) )
        parts.pop
        as_string = parts.join("_")
      end
      as_string = "word" if as_string == "name"
      as_string = "message" if as_string == "next_message"
      as_string = "message" if as_string == "caller"
      as_string = "named_list" if as_string == "arguments"
      sym = as_string.camelise.to_sym
      clazz = Parfait.object_space.get_class_by_name(sym)
      raise "Not implemented/found object #{name}:#{sym}" unless clazz
      return clazz.instance_type
    end

    def if_zero( label )
      @source_used = true
      add_code Risc::IsZero.new(@source , label)
    end
    def if_not_zero( label )
      @source_used = true
      add_code Risc::IsNotZero.new(@source , label)
    end
    def if_minus( label )
      @source_used = true
      add_code Risc::IsMinus.new(@source , label)
    end
    def branch( label )
      @source_used = true
      add_code Risc::Branch.new(@source, label)
    end

    # To avoid many an if, it can be handy to swap variable names.
    # But since the names in the builder are not variables, we need this method.
    # As it says, swap the two names around. Names must exist
    def swap_names(left , right)
      left , right = left.to_s , right.to_s
      l = @names[left]
      r = @names[right]
      raise "No such name #{left}" unless l
      raise "No such name #{right}" unless r
      @names[left] = r
      @names[right] = l
    end

    # Reset the names stored by the builder. The names are sort of variables names
    # that can be used in the build block due to method_missing magic.
    #
    # But just as the compiler has reset_regs, the builder has this reset button, to
    # start fresh. Quite crude for now, and only used in allocate_int
    #
    # Compiler regs are reset as well
    def reset_names
      @names = {}
      compiler.reset_regs
    end

    # Build code using dsl (see __init__ or MessageSetup for examples)
    # names (that ruby would resolve to a variable/method) are converted
    # to registers. << means assignment and [] is supported both on
    # L and R values (but only one at a time). R values may also be constants.
    #
    # Basically this allows to create LoadConstant, RegToSlot, SlotToReg and
    # Transfer instructions with extremely readable code.
    # example:
    #  space << Parfait.object_space # load constant
    #  message[:receiver] << space  #make current message (r0) receiver the space
    #
    # build result is added to compiler directly
    #
    def build(&block)
      instance_eval(&block)
    end

    # add code straight to the compiler
    def add_code(ins)
      @compiler.add_code(ins)
      return ins
    end

    # allocate int fetches a new int, for sure. It is a builder method, rather than
    # an inbuilt one, to avoid call overhead for 99.9%
    # The factories allocate in 1k, so only when that runs out do we really need a call.
    # Note:
    #   Unfortunately (or so me thinks), this creates code bloat, as the calling is
    #   included in 100%, but only needed in 0.1. Risc-levelBlocks or Macros may be needed.
    #   as the calling in (the same) 30-40 instructions for every basic int op.
    #
    # The method
    # - grabs a Integer instance from the Integer factory
    # - checks for nil and calls (get_more) for more if needed
    # - returns the RiscValue (Regster) where the object is found
    #
    # The implicit condition is that the method is called at the entry of a method.
    # It uses a fair few registers and resets all at the end. The returned object
    # will always be in r1, because the method resets, and all others will be clobbered
    def allocate_int
      compiler.reset_regs
      integer = self.integer!
      build do
        factory! << Parfait.object_space.get_factory_for(:Integer)
        integer << factory[:next_object]
        object! << Parfait.object_space.nil_object
        object - integer
        if_not_zero cont_label
        integer_2! << factory[:reserve]
        factory[:next_object] << integer_2
        call_get_more
        integer << factory[:next_object]
        add_code cont_label
        integer_2 << integer[:next_integer]
        factory[:next_object] << integer_2
      end
      reset_names
      integer_tmp!
    end

    # Call_get_more calls the method get_more on the factory (see there).
    # From the callers perspective the method ensures there is a next_object.
    #
    # Calling is three step process
    # - setting up the next message
    # - moving receiver (factory) and arguments (none)
    # - issuing the call
    # These steps shadow the MomInstructions MessageSetup, ArgumentTransfer and SimpleCall
    def call_get_more
      factory = Parfait.object_space.get_factory_for( :Integer )
      calling = factory.get_type.get_method( :get_more )
      calling = Parfait.object_space.get_main #until we actually parse Factory
      Mom::MessageSetup.new( calling ).build_with( self )
      self.build do
        factory_reg! << factory
        message[:receiver] << factory_reg
      end
      Mom::SimpleCall.new(calling).to_risc(compiler)
    end

    def add_new_int( source , from, to )
      to.set_builder( self )    # esecially div10 comes in without having used builder
      from.set_builder( self )  # not named regs, different regs ==> silent errors
      build do
        factory! << Parfait.object_space.get_factory_for(:Integer)
        to << factory[:next_object]
        integer_2! << to[:next_integer]
        factory[:next_object] << integer_2
        to[Parfait::Integer.integer_index] << from
      end
    end
  end

end
