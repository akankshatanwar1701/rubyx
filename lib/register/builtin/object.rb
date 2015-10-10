module Register
  module Builtin
    class Object
      module ClassMethods

        # main entry point, ie __init__ calls this
        # defined here as empty, to be redefined
        def main context
          function = Virtual::MethodSource.create_method(:Object, :int , :main , [])
          return function
        end

        # in ruby, how this goes is
        #  def _get_instance_variable var
        #     i = self.index_of(var)
        #     return at_index(i)
        #  end
        # The at_index is just "below" the api, something we need but don't want to expose,
        # so we can't code the above in ruby
        def _get_instance_variable context , name = :int
          get_function = Virtual::MethodSource.create_method(:Object,:int, :_get_instance_variable , [  ] )
          return get_function
  #         me = get_function.receiver
  #         var_name = get_function.args.first
  #         return_to = get_function.return_type
  #
  #         index_function = ::Virtual.machine.space.get_class_by_name(:Object).resolve_method(:index_of)
  # #        get_function.push( [me] )
  # #        index = get_function.call( index_function )
  #
  #         after_body = get_function.new_block("after_index")
  #         get_function.current after_body
  #
  # #        get_function.pop([me])
  # #        return_to.at_index( get_function , me , return_to )
  #
  # #        get_function.set_return return_to
  #         return get_function
        end

        def _set_instance_variable(context , name = :int , value = :int )
          set_function = Virtual::MethodSource.create_method(:Object,:int,:_set_instance_variable ,[] )
          return set_function
          # receiver set_function
          # me = set_function.receiver
          # var_name = set_function.args.first
          # return_to = set_function.return_type
          # index_function = context.object_space.get_class_by_name(:Object).resolve_method(:index_of)
          # set_function.push( [me] )
          # set_function.call( index_function )
          # after_body = set_function.new_block("after_index")
          #
          # set_function.current after_body
          # set_function.pop([me])
          # return_to.at_index( set_function , me , return_to )
          # set_function.set_return return_to
          # return set_function
        end

        def _get_singleton_method(context , name )
          raise name
        end
        def _add_singleton_method(context, method)
          raise "4"
        end
        def initialize(context)
          raise "4"
        end
      end
      extend ClassMethods
    end
  end
end

require_relative "integer"
require_relative "kernel"
require_relative "word"
