
require "ruby2cext/error"
require "ruby2cext/plugin"
require "ruby2cext/plugins/util"

module Ruby2CExtension::Plugins

class InlineBuiltin < Ruby2CExtension::Plugin

    include Util
    extend Util

    def initialize(compiler)
        super(compiler)
        compiler.add_preprocessor(:call, &method(:call))
        compiler.add_preprocessor(:vcall, &method(:call))
        compiler.add_preprocessor(:fcall, &method(:call))
        compiler.add_preprocessor(:inline_pass, &method(:inline_pass))
    end

    def inline_pass(cfun, node)
        node.shift
        node
    end

    def call(cfun, node)
        hash = node.last
        recv = hash[:recv] || [:self, {}]
        klass = deduce_type(recv)
        mid = hash[:mid]
        inline = (INLINE[klass]||{})[mid] || INLINE[nil][mid] or return node
        arity = inline.arity
        arity = -arity-1 if (extra_allowed = (arity<0))
        arity -= 2
        arity>=0 or return node
        args = hash[:args] || [:array, []]
        args = split_args(arity, extra_allowed, args) or return node
        inline[cfun, recv, *args] || node
    end
    
    EQUAL = lambda { |cfun, this, that| 
        values(cfun, 0, this, that) { |this, that| %{
            (#{this}==(#{that}) ? Qtrue : Qfalse)
        }}
    }
    
    def self.call(cfun, this, mid, *args)
        cfun.comp([:call, {
            :recv => this,
            :mid => mid,
            :args => [:array, args]
        }])
    end
    
    def self.pass_call(cfun, this, mid, *args)
        cfun.comp([:inline_pass, :call, {
            :recv => this,
            :mid => mid,
            :args => [:array, args]
        }])
    end
    
    INLINE = {}
    
    INLINE[nil] = {
        :__id__ => lambda { |cfun, this|
            values(cfun, 1, this) { |this| %{(
                (TYPE(#{this}) == T_SYMBOL) ?
                    rb_obj_id(#{this}) :
                (SPECIAL_CONST_P(#{this})) ?
                    LONG2NUM((long)(#{this})) :
                    (VALUE)((long)(#{this})|FIXNUM_FLAG)
            )}}
            
        },
        :__send__ => lambda { |cfun, this, method, *args|
            args = args[0]
            this = cfun.comp(this);
            cfun.c_scope_res {
                cfun.l "VALUE recv = #{this};"
                cfun.build_args(args)
                %{rb_funcall2(#{this}, rb_to_id(#{cfun.comp(method)}), argc, argv)}
            }
        }
    }

    INLINE[NilClass] = {
        :equal? => EQUAL,
        :eql?   => EQUAL,
        :'=='   => EQUAL,
        :'==='  => EQUAL,
    }
    
    INLINE[FalseClass] = {
        :equal? => EQUAL,
        :eql?   => EQUAL,
        :'=='   => EQUAL,
        :'==='  => EQUAL,
    }
    
    INLINE[TrueClass] = {
        :equal? => EQUAL,
        :eql?   => EQUAL,
        :'=='   => EQUAL,
        :'==='  => EQUAL,
    }
    
    INLINE[Symbol] = {
        :equal? => EQUAL,
        :eql?   => EQUAL,
        :'=='   => EQUAL,
        :'==='  => EQUAL,
    }

    def self.fix_binary(op, rop=nil)
        rop = nil
        fix = lambda { |this, that|
            %{LONG2NUM(FIX2LONG(#{this}) #{op} FIX2LONG(#{that}))}
        }
        lambda { |cfun, this, that|
            case deduce_type(that)
            when nil
                values(cfun, 1, that, this) { |that, this|
                    cfun.c_if(%{FIXNUM_P(#{that})}) {
                        cfun.assign_res(fix[this, that])
                    }
                    cfun.c_else {
                        cfun.assign_res(
                            rop ? call(cfun, that, rop, this) :
                                  pass_call(cfun, this, op, that)
                        )
                    }
                    "res"
                }
            when Fixnum
                fix[cfun.comp(this), cfun.comp(that)]
            else
                rop && call(cfun, this, rop, that)
            end
        }
    end
    
    def self.fix_compare(op, rop=nil)
        rop = nil
        fix = lambda { |this, that|
            %{((FIX2LONG(#{this}) #{op} FIX2LONG(#{that}))?Qtrue:Qfalse)}
        }
        lambda { |cfun, this, that|
            case deduce_type(that)
            when nil
                values(cfun, 1, that, this) { |that, this|
                    cfun.c_if(%{FIXNUM_P(#{that})}) {
                        cfun.assign_res(fix[this, that])
                    }
                    cfun.c_else {
                        cfun.assign_res(
                            rop ? call(cfun, that, rop, this) :
                                  pass_call(cfun, this, op, that)
                        )
                    }
                    "res"
                }
            when Fixnum
                fix[cfun.comp(this), cfun.comp(that)]
            else
                rop && call(cfun, this, rop, that)
            end
        }
    end

    INLINE[Fixnum] = {
        :equal? => EQUAL,
        :eql?   => EQUAL,
        :'=='   => lambda { |cfun, this, that|
            case deduce_type(that)
            when Fixnum
                EQUAL[cfun, this, that]
            when nil
                values(cfun, 2, this, that) { |this, that| %{
                    ((#{this}==#{that}) ? Qtrue :
                      FIXNUM_P(#{that}) ? Qfalse :
                      rb_funcall(#{that}, #{cfun.sym(:==)}, 1, #{this}))
                }}
            end
        },
        :'<=>'  => lambda { |cfun, this, that|
            case deduce_type(that)
            when Fixnum
                values(cfun, 2, this, that) { |this, that|
                    %{INT2FIX((#{that}<#{this})-(#{this}<#{that}))}
                }
            when nil
                values(cfun, 2, this, that) { |this, that| %{
                    ((#{this}==#{that}) ? INT2FIX(0) :
                      FIXNUM_P(#{that}) ?
                        ((FIX2LONG(#{this})>FIX2LONG(#{that})) ? INT2FIX(1) :
                          INT2FIX(-1)) :
                      rb_funcall(#{this}, #{cfun.sym(op)}, 1, #{that}))
                }}
            end
        },
        :'+'    => fix_binary(:'+', :'+'),
        :'-'    => fix_binary(:'-'),
        :'>'    => fix_compare(:'>', :'<'),
        :'>='   => fix_compare(:'>=', :'<='),
        :'<'    => fix_compare(:'<', :'>'),
        :'<='   => fix_compare(:'<=', :'>='),
        :'&'    => fix_binary(:'&', :'&'),
        :'|'    => fix_binary(:'|', :'|'),
        :'^'    => fix_binary(:'^', :'^'),
    }
    INLINE[Fixnum][:'==='] = INLINE[Fixnum][:'==']

end

end


