
require "ruby2cext/error"
require "ruby2cext/plugin"
require "ruby2cext/plugins/util"

module Ruby2CExtension::Plugins

class DirectSelfCall < Ruby2CExtension::Plugin

    include Util

    def call(cfun, node)
        hash = node.last
        recv = hash[:recv]
        return node if recv && (!(Array === recv) || !recv.first.equal?(:self))
        mid = hash[:mid]
        name = @ruby2c_method[[@scope,mid]]
        return node unless name
        args = hash[:args] || [:array, []]
        if Array == args and args.first.equal?(:array) and args.last.empty?
            "#{name}(0, 0, #{cfun.get_self})"
        else
            cfun.c_scope_res {
                cfun.build_args(args)
                "#{name}(argc, argv, #{cfun.get_self})"
            }
        end
    end

    def initialize(compiler)
        super
        @ruby2c_method = {}
        @scope = nil
        compiler.add_preprocessor(:defn) { |cfun, node|
            scope0 = @scope
            hash = node.last
            mid = hash[:mid]
            @scope = cfun
            name0 = "\0#{cfun.__id__}\0#{mid}\0"
            name = name0.clone
            @ruby2c_method[[cfun,mid]] = name
            _add_fun = compiler.method(:add_fun)
            klass = (class << compiler;self;end)
            klass.send(:define_method, :add_fun) { |code, base_name|
                name.replace(_add_fun[code, base_name])
                code.gsub!(name0, name)
                name.clone
            }
            ret = cfun.comp_defn(hash)
            unless cfun.scope.vmode.equal?(:private)
                @ruby2c_method.delete([cfun,mid])
            end
            @scope = scope0
            klass.send(:define_method, :add_fun, _add_fun.unbind)
            ret
        }
        compiler.add_preprocessor(:call, &method(:call))
        compiler.add_preprocessor(:vcall, &method(:call))
        compiler.add_preprocessor(:fcall, &method(:call))
    end

end

end


