module SlotMachine

  # Dynamic method resolution is at the heart of a dynamic language, and here
  # is the SlotMachine level instruction to do it.
  #
  # When the static type can not be determined a CacheEntry is used to store
  # type and method of the resolved method. The CacheEntry is shared with
  # DynamicCall instruction who is responsible for calling the method in the entry.
  #
  # This instruction resolves the method, in case the types don't match (and
  # at least on first encouter)
  #
  # This used to be a method, but we don't really need the method setup etc
  #
  class ResolveMethod < Instruction
    attr :cache_entry , :name

    # pass in source (SolStatement)
    # name of the method (don't knwow the actaual method)
    # and the cache_entry
    def initialize(source , name , cache_entry)
      super(source)
      @name = name
      @cache_entry = cache_entry
    end

    def to_s
      "ResolveMethod #{name}"
    end

    # When the method is resolved, a cache_entry is used to hold the result.
    # That cache_entry (holding type and method) is checked before, and
    # needs to be updated by this instruction.
    #
    # We use the type stored in the cache_entry to check the methods if any of it's
    # names are the same as the given @name
    #
    # currently a fail results in sys exit
    def to_risc( compiler )
      builder = compiler.builder(self)
      word = builder.load_object(@name)
      entry = builder.load_object(@cache_entry)
      while_start_label = Risc.label(to_s, "resolve_#{name}_#{object_id}")
      ok_label = Risc.label(to_s, "ok_resolve_#{name}_#{object_id}")
      exit_label = Risc.label(to_s, "exit_resolve_#{name}_#{object_id}")
      builder.build do
        callable_method = entry[:cached_type][:methods].to_reg

        add_code while_start_label

        object = load_object Parfait.object_space.nil_object
        object.op :- , callable_method
        if_zero exit_label

        name = callable_method[:name].to_reg
        name.op :- , word

        if_zero ok_label

        next_method = callable_method[:next_callable].to_reg
        callable_method << next_method

        branch  while_start_label

        add_code exit_label
        MethodMissing.new(compiler.source_name , word.symbol).to_risc(compiler)

        add_code ok_label
        entry[:cached_method] << callable_method
      end
    end

  end
end
