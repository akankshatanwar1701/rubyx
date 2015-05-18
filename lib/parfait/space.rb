
# A Space is a collection of pages. It stores objects, the data for the objects,
# not references. See Page for more detail.

# Pages are stored by the object size they represent in a hash.

# Space and Page work together in making *new* objects available.
# "New" is slightly misleading in that normal operation only ever
# recycles objects.

require "register/builtin/object"

module Parfait
  # The Space contains all objects for a program. In functional terms it is a program, but in oo
  # it is a collection of objects, some of which are data, some classes, some functions

  # The main entry is a function called (of all things) "main", This _must be supplied by the compling
  # There is a start and exit block that call main, which receives an List of strings

  # While data ususally would live in a .data section, we may also "inline" it into the code
  # in an oo system all data is represented as objects

  class Space < Object

    def initialize
      super()
      @classes = Parfait::Dictionary.new_object
      #global objects (data)
      @objects = []
      @symbols = []
      @frames = 100.times.collect{ ::Parfait::Frame.new([],[])}
      @messages = 100.times.collect{ ::Parfait::Message.new }
      @next_message = @messages.first
      @next_frame = @frames.first
    end
    attr_reader :classes , :objects , :symbols,:messages, :next_message , :next_frame

    @@SPACE = { :names => [:classes,:objects,:symbols,:messages, :next_message , :next_frame] ,
                :types => [Virtual::Reference,Virtual::Reference,Virtual::Reference,Virtual::Reference,Virtual::Reference]}
    def old_layout
      @@SPACE
    end

    # Objects are data and get assembled after functions
    def add_object o
      return if @objects.include?(o)
      @objects << o
      if o.is_a? Symbol
        @symbols << o
      end
    end

    # this is the way to instantiate classes (not Parfait::Class.new)
    # so we get and keep exactly one per name
    def get_class_by_name name
      raise "uups #{name}.#{name.class}" unless name.is_a? String or name.is_a? Word
      c = @classes[name]
      c
    end

    def create_class name , variable_names
      c = Class.new_object(name)
      c.set_instance_names Parfait.new_list(variable_names)
      @classes[name] = c
    end

    def mem_length
      padded_words( 5 )
    end
  end
  # ObjectSpace
  # :each_object, :garbage_collect, :define_finalizer, :undefine_finalizer, :_id2ref, :count_objects
end