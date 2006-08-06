
require "ruby2cext/error"
require "ruby2cext/plugin"

module Ruby2CExtension::Plugins

	class BuiltinMethods < Ruby2CExtension::Plugin
		# for public methods of builtin types with a fixed arity, which don't do anything with blocks

		SUPPORTED_BUILTINS = [:Array, :Bignum, :FalseClass, :Fixnum, :Float, :Hash, :NilClass, :Regexp, :String, :Symbol, :TrueClass]

		NO_CLASS_CHECK_BUILTINS = [:FalseClass, :Fixnum, :NilClass, :Symbol, :TrueClass]

		COMMON_METHODS = [ # all supported builtins use these methods from Kernel
			 [:__id__, 0, :Kernel],
			 [:class, 0, :Kernel],
			 [:clone, 0, :Kernel],
			 [:dup, 0, :Kernel],
			 [:freeze, 0, :Kernel],
			 [:instance_variables, 0, :Kernel],
			 [:object_id, 0, :Kernel],
			 [:taint, 0, :Kernel],
			 [:tainted?, 0, :Kernel],
			 [:untaint, 0, :Kernel],
			 [:equal?, 1, :Kernel],
			 [:instance_of?, 1, :Kernel],
			 [:instance_variable_get, 1, :Kernel],
			 [:is_a?, 1, :Kernel],
			 [:kind_of?, 1, :Kernel],
			 [:method, 1, :Kernel],
			 [:instance_variable_set, 2, :Kernel],
		]

		METHODS = {
			:Array => [
				[:[], 1, nil, nil, -1],
				[:[], 2, nil, nil, -1],
				[:first, 0, nil, nil, -1],
				[:first, 1, nil, nil, -1],
				[:insert, 2, nil, nil, -1],
				[:insert, 3, nil, nil, -1],
				[:join, 0, nil, nil, -1],
				[:join, 1, nil, nil, -1],
				[:last, 0, nil, nil, -1],
				[:last, 1, nil, nil, -1],
				[:push, 1, nil, nil, -1],
				[:slice, 1, nil, nil, -1],
				[:slice, 2, nil, nil, -1],
				[:slice!, 1, nil, nil, -1],
				[:slice!, 2, nil, nil, -1],
				[:unshift, 1, nil, nil, -1],
				[:values_at, 1, nil, nil, -1],
				[:values_at, 2, nil, nil, -1],
				[:values_at, 3, nil, nil, -1],
				[:values_at, 4, nil, nil, -1],
				[:clear, 0],
				[:compact, 0],
				[:compact!, 0],
				[:empty?, 0],
				[:flatten, 0],
				[:flatten!, 0],
				[:frozen?, 0],
				[:hash, 0],
				[:inspect, 0],
				[:length, 0],
				[:nitems, 0],
				[:pop, 0],
				[:reverse, 0],
				[:reverse!, 0],
				[:shift, 0],
				[:size, 0],
				[:to_a, 0],
				[:to_ary, 0],
				[:to_s, 0],
				[:transpose, 0],
				[:uniq, 0],
				[:uniq!, 0],
				[:&, 1],
				[:|, 1],
				[:*, 1],
				[:+, 1],
				[:-, 1],
				[:<<, 1],
				[:<=>, 1],
				[:==, 1],
				[:assoc, 1],
				[:at, 1],
				[:concat, 1],
				[:delete_at, 1],
				[:eql?, 1],
				[:include?, 1],
				[:index, 1],
				[:rassoc, 1],
				[:replace, 1],
				[:rindex, 1],
				[:entries, 0, :Enumerable],
				[:member?, 1, :Enumerable],
				[:nil?, 0, :Kernel],
				[:===, 1, :Kernel],
				[:=~, 1, :Kernel],
			],
			:Bignum => [
				[:to_s, 0, nil, nil, -1],
				[:to_s, 1, nil, nil, -1],
				[:-@, 0],
				[:abs, 0],
				[:hash, 0],
				[:size, 0],
				[:to_f, 0],
				[:~, 0],
				[:%, 1, nil, [:Fixnum, :Bignum]],
				[:&, 1],
				[:*, 1, nil, [:Fixnum, :Bignum, :Float]],
				[:**, 1, nil, [:Fixnum, :Bignum, :Float]],
				[:+, 1, nil, [:Fixnum, :Bignum, :Float]],
				[:-, 1, nil, [:Fixnum, :Bignum, :Float]],
				[:/, 1, nil, [:Fixnum, :Bignum, :Float]],
				[:<<, 1],
				[:<=>, 1, nil, [:Fixnum, :Bignum, :Float]],
				[:==, 1],
				[:>>, 1],
				[:[], 1],
				[:^, 1],
				[:coerce, 1],
				[:div, 1, nil, [:Fixnum, :Bignum, :Float]],
				[:divmod, 1, nil, [:Fixnum, :Bignum]],
				[:eql?, 1],
				[:modulo, 1, nil, [:Fixnum, :Bignum]],
				[:quo, 1, nil, [:Fixnum, :Bignum, :Float]],
				[:remainder, 1, nil, [:Fixnum, :Bignum]],
				[:|, 1],
				[:<, 1, :Comparable],
				[:<=, 1, :Comparable],
				[:>, 1, :Comparable],
				[:>=, 1, :Comparable],
				[:between?, 2, :Comparable],
				[:ceil, 0, :Integer],
				[:chr, 0, :Integer],
				[:floor, 0, :Integer],
				[:integer?, 0, :Integer],
				[:next, 0, :Integer],
				[:round, 0, :Integer],
				[:succ, 0, :Integer],
				[:to_i, 0, :Integer],
				[:to_int, 0, :Integer],
				[:truncate, 0, :Integer],
				[:+@, 0, :Numeric],
				[:nonzero?, 0, :Numeric],
				[:zero?, 0, :Numeric],
				[:frozen?, 0, :Kernel],
				[:inspect, 0, :Kernel],
				[:nil?, 0, :Kernel],
				[:to_a, 0, :Kernel],
				[:===, 1, :Kernel],
				[:=~, 1, :Kernel],
			],
			:FalseClass => [
				[:to_s, 0],
				[:&, 1],
				[:^, 1],
				[:|, 1],
				[:frozen?, 0, :Kernel],
				[:hash, 0, :Kernel],
				[:inspect, 0, :Kernel],
				[:nil?, 0, :Kernel],
				[:to_a, 0, :Kernel],
				[:==, 1, :Kernel],
				[:===, 1, :Kernel],
				[:=~, 1, :Kernel],
				[:eql?, 1, :Kernel],
			],
			:Fixnum => [
				[:to_s, 0, nil, nil, -1],
				[:to_s, 1, nil, nil, -1],
				[:-@, 0],
				[:abs, 0],
				[:id2name, 0],
				[:size, 0],
				[:to_sym, 0],
				[:to_f, 0],
				[:zero?, 0],
				[:~, 0],
				[:+, 1, nil, [:Fixnum, :Float]],
				[:-, 1, nil, [:Fixnum, :Float]],
				[:*, 1, nil, [:Fixnum, :Float]],
				[:**, 1, nil, [:Fixnum, :Float]],
				[:/, 1, nil, [:Fixnum]],
				[:div, 1, nil, [:Fixnum]],
				[:%, 1, nil, [:Fixnum]],
				[:modulo, 1, nil, [:Fixnum]],
				[:divmod, 1, nil, [:Fixnum]],
				[:quo, 1, nil, [:Fixnum]],
				[:<=>, 1, nil, [:Fixnum]],
				[:>, 1, nil, [:Fixnum]],
				[:>=, 1, nil, [:Fixnum]],
				[:<, 1, nil, [:Fixnum]],
				[:<=, 1, nil, [:Fixnum]],
				[:==, 1],
				[:&, 1],
				[:|, 1],
				[:^, 1],
				[:[], 1],
				[:<<, 1],
				[:>>, 1],
				[:between?, 2, :Comparable],
				[:+@, 0, :Numeric],
				[:nonzero?, 0, :Numeric],
				[:coerce, 1, :Numeric],
				[:eql?, 1, :Numeric],
				[:remainder, 1, :Numeric],
				[:ceil, 0, :Integer],
				[:chr, 0, :Integer],
				[:floor, 0, :Integer],
				[:integer?, 0, :Integer],
				[:next, 0, :Integer],
				[:round, 0, :Integer],
				[:succ, 0, :Integer],
				[:to_i, 0, :Integer],
				[:to_int, 0, :Integer],
				[:truncate, 0, :Integer],
				[:frozen?, 0, :Kernel],
				[:hash, 0, :Kernel],
				[:inspect, 0, :Kernel],
				[:nil?, 0, :Kernel],
				[:to_a, 0, :Kernel],
				[:===, 1, :Kernel],
				[:=~, 1, :Kernel],
			],
			:Float => [
				[:-@, 0],
				[:to_s, 0],
				[:hash, 0],
				[:to_f, 0],
				[:abs, 0],
				[:zero?, 0],
				[:to_i, 0],
				[:to_int, 0],
				[:floor, 0],
				[:ceil, 0],
				[:round, 0],
				[:truncate, 0],
				[:nan?, 0],
				[:infinite?, 0],
				[:finite?, 0],
				[:coerce, 1],
				[:eql?, 1],
				[:==, 1],
				[:+, 1, nil, [:Fixnum, :Bignum, :Float]],
				[:-, 1, nil, [:Fixnum, :Bignum, :Float]],
				[:*, 1, nil, [:Fixnum, :Bignum, :Float]],
				[:/, 1, nil, [:Fixnum, :Bignum, :Float]],
				[:%, 1, nil, [:Fixnum, :Bignum, :Float]],
				[:modulo, 1, nil, [:Fixnum, :Bignum, :Float]],
				[:divmod, 1, nil, [:Fixnum, :Bignum, :Float]],
				[:**, 1, nil, [:Fixnum, :Bignum, :Float]],
				[:<=>, 1, nil, [:Fixnum, :Bignum, :Float]],
				[:>, 1, nil, [:Fixnum, :Bignum, :Float]],
				[:>=, 1, nil, [:Fixnum, :Bignum, :Float]],
				[:<, 1, nil, [:Fixnum, :Bignum, :Float]],
				[:<=, 1, nil, [:Fixnum, :Bignum, :Float]],
				[:between?, 2, :Comparable],
				[:+@, 0, :Numeric],
				[:integer?, 0, :Numeric],
				[:nonzero?, 0, :Numeric],
				[:div, 1, :Numeric],
				[:quo, 1, :Numeric],
				[:remainder, 1, :Numeric],
				[:frozen?, 0, :Kernel],
				[:inspect, 0, :Kernel],
				[:nil?, 0, :Kernel],
				[:to_a, 0, :Kernel],
				[:===, 1, :Kernel],
				[:=~, 1, :Kernel],
			],
			:Hash => [
				[:default, 0, nil, nil, -1],
				[:default, 1, nil, nil, -1],
				[:values_at, 1, nil, nil, -1],
				[:values_at, 2, nil, nil, -1],
				[:values_at, 3, nil, nil, -1],
				[:values_at, 4, nil, nil, -1],
				[:clear, 0],
				[:default_proc, 0],
				[:empty?, 0],
				[:inspect, 0],
				[:invert, 0],
				[:keys, 0],
				[:length, 0],
				[:rehash, 0],
				[:shift, 0],
				[:size, 0],
				[:to_a, 0],
				[:to_hash, 0],
				[:to_s, 0],
				[:values, 0],
				[:==, 1],
				[:[], 1],
				[:default=, 1],
				[:delete, 1],
				[:has_key?, 1],
				[:has_value?, 1],
				[:include?, 1],
				[:index, 1],
				[:key?, 1],
				[:member?, 1],
				[:replace, 1],
				[:value?, 1],
				[:store, 2],
				[:entries, 0, :Enumerable],
				[:frozen?, 0, :Kernel],
				[:hash, 0, :Kernel],
				[:nil?, 0, :Kernel],
				[:===, 1, :Kernel],
				[:=~, 1, :Kernel],
				[:eql?, 1, :Kernel],
			],
			:NilClass => [
				[:inspect, 0],
				[:nil?, 0],
				[:to_a, 0],
				[:to_f, 0],
				[:to_i, 0],
				[:to_s, 0],
				[:&, 1],
				[:^, 1],
				[:|, 1],
				[:frozen?, 0, :Kernel],
				[:hash, 0, :Kernel],
				[:==, 1, :Kernel],
				[:===, 1, :Kernel],
				[:=~, 1, :Kernel],
				[:eql?, 1, :Kernel],
			],
			:Regexp => [
				[:casefold?, 0],
				[:hash, 0],
				[:inspect, 0],
				[:kcode, 0],
				[:options, 0],
				[:source, 0],
				[:to_s, 0],
				[:~, 0],
				[:==, 1],
				[:===, 1],
				[:=~, 1],
				[:eql?, 1],
				[:match, 1],
				[:frozen?, 0, :Kernel],
				[:nil?, 0, :Kernel],
				[:to_a, 0, :Kernel],
			],
			:String => [
				[:[], 1, nil, nil, -1],
				[:[], 2, nil, nil, -1],
				[:center, 1, nil, nil, -1],
				[:center, 2, nil, nil, -1],
				[:chomp, 1, nil, nil, -1],
				[:chomp, 2, nil, nil, -1],
				[:chomp!, 1, nil, nil, -1],
				[:chomp!, 2, nil, nil, -1],
				[:count, 1, nil, nil, -1],
				[:count, 2, nil, nil, -1],
				[:count, 3, nil, nil, -1],
				[:delete, 1, nil, nil, -1],
				[:delete, 2, nil, nil, -1],
				[:delete, 3, nil, nil, -1],
				[:delete!, 1, nil, nil, -1],
				[:delete!, 2, nil, nil, -1],
				[:delete!, 3, nil, nil, -1],
				[:index, 1, nil, nil, -1],
				[:index, 2, nil, nil, -1],
				[:ljust, 1, nil, nil, -1],
				[:ljust, 2, nil, nil, -1],
				[:rindex, 1, nil, nil, -1],
				[:rindex, 2, nil, nil, -1],
				[:rjust, 1, nil, nil, -1],
				[:rjust, 2, nil, nil, -1],
				[:slice, 1, nil, nil, -1],
				[:slice, 2, nil, nil, -1],
				[:slice!, 1, nil, nil, -1],
				[:slice!, 2, nil, nil, -1],
				[:split, 0, nil, nil, -1],
				[:split, 1, nil, nil, -1],
				[:split, 2, nil, nil, -1],
				[:squeeze, 1, nil, nil, -1],
				[:squeeze, 2, nil, nil, -1],
				[:squeeze, 3, nil, nil, -1],
				[:squeeze!, 1, nil, nil, -1],
				[:squeeze!, 2, nil, nil, -1],
				[:squeeze!, 3, nil, nil, -1],
				[:to_i, 0, nil, nil, -1],
				[:to_i, 1, nil, nil, -1],
				[:capitalize, 0],
				[:capitalize!, 0],
				[:chop, 0],
				[:chop!, 0],
				[:downcase, 0],
				[:downcase!, 0],
				[:dump, 0],
				[:empty?, 0],
				[:hash, 0],
				[:hex, 0],
				[:inspect, 0],
				[:intern, 0],
				[:length, 0],
				[:lstrip, 0],
				[:lstrip!, 0],
				[:next, 0],
				[:next!, 0],
				[:oct, 0],
				[:reverse, 0],
				[:reverse!, 0],
				[:rstrip, 0],
				[:rstrip!, 0],
				[:size, 0],
				[:strip, 0],
				[:strip!, 0],
				[:succ, 0],
				[:succ!, 0],
				[:swapcase, 0],
				[:swapcase!, 0],
				[:to_f, 0],
				[:to_s, 0],
				[:to_str, 0],
				[:to_sym, 0],
				[:upcase, 0],
				[:upcase!, 0],
				[:%, 1],
				[:*, 1],
				[:+, 1],
				[:<<, 1],
				[:<=>, 1],
				[:==, 1],
				[:=~, 1],
				[:casecmp, 1],
				[:concat, 1],
				[:crypt, 1],
				[:eql?, 1],
				[:include?, 1],
				[:match, 1],
				[:replace, 1],
				[:insert, 2],
				[:tr, 2],
				[:tr!, 2],
				[:tr_s, 2],
				[:tr_s!, 2],
				[:<, 1, :Comparable],
				[:<=, 1, :Comparable],
				[:>, 1, :Comparable],
				[:>=, 1, :Comparable],
				[:between?, 2, :Comparable],
				[:entries, 0, :Enumerable],
				[:to_a, 0, :Enumerable],
				[:member?, 1, :Enumerable],
				[:frozen?, 0, :Kernel],
				[:nil?, 0, :Kernel],
				[:===, 1, :Kernel],
			],
			:Symbol => [
				[:id2name, 0],
				[:inspect, 0],
				[:to_i, 0],
				[:to_int, 0],
				[:to_s, 0],
				[:to_sym, 0],
				[:===, 1],
				[:frozen?, 0, :Kernel],
				[:hash, 0, :Kernel],
				[:nil?, 0, :Kernel],
				[:to_a, 0, :Kernel],
				[:==, 1, :Kernel],
				[:=~, 1, :Kernel],
				[:eql?, 1, :Kernel],
			],
			:TrueClass => [
				[:to_s, 0],
				[:&, 1],
				[:^, 1],
				[:|, 1],
				[:frozen?, 0, :Kernel],
				[:hash, 0, :Kernel],
				[:inspect, 0, :Kernel],
				[:nil?, 0, :Kernel],
				[:to_a, 0, :Kernel],
				[:==, 1, :Kernel],
				[:===, 1, :Kernel],
				[:=~, 1, :Kernel],
				[:eql?, 1, :Kernel],
			],
		}

		METHOD_NAME_MAPPINGS = Hash.new { |h, k|
			case k.to_s
			when /\A\w+\z/
				h[k] = "builtinoptmeth_#{k}"
			when /\A\w+\?\z/
				h[k] = "builtinoptmeth_#{k.to_s[0..-2]}__pred"
			when /\A\w+!\z/
				h[k] = "builtinoptmeth_#{k.to_s[0..-2]}__bang"
			when /\A\w+=\z/
				h[k] = "builtinoptmeth_#{k.to_s[0..-2]}__assign"
			else
				raise Ruby2CExtension::Ruby2CExtError::Bug, "unexpected method name: #{k.inspect}"
			end
		}
		METHOD_NAME_MAPPINGS.merge!({
			:+@  => "builtinoptop_uplus",
			:-@  => "builtinoptop_uminus",
			:+   => "builtinoptop_plus",
			:-   => "builtinoptop_minus",
			:*   => "builtinoptop_mul",
			:/   => "builtinoptop_div",
			:**  => "builtinoptop_pow",
			:%   => "builtinoptop_mod",
			:~   => "builtinoptop_rev",
			:==  => "builtinoptop_equal",
			:=== => "builtinoptop_eqq",
			:=~  => "builtinoptop_match",
			:<=> => "builtinoptop_cmp",
			:>   => "builtinoptop_gt",
			:>=  => "builtinoptop_ge",
			:<   => "builtinoptop_lt",
			:<=  => "builtinoptop_le",
			:&   => "builtinoptop_and",
			:|   => "builtinoptop_or",
			:^   => "builtinoptop_xor",
			:[]  => "builtinoptop_aref",
			:<<  => "builtinoptop_lshift",
			:>>  => "builtinoptop_rshift",
		})

		BUILTIN_TYPE_MAP = Hash.new { |h, k|
			h[k] = "T_#{k}".upcase
		}
		BUILTIN_TYPE_MAP.merge!({
			:NilClass => "T_NIL",
			:TrueClass => "T_TRUE",
			:FalseClass => "T_FALSE",
		})

		BUILTIN_C_VAR_MAP = Hash.new { |h, k|
			h[k] = "rb_#{Module.const_get(k).instance_of?(Module) ? "m" : "c"}#{k}"
		}

		attr_reader :methods, :function_names

		def initialize(compiler, builtins)
			super(compiler)
			builtins = SUPPORTED_BUILTINS & builtins # "sort" and unique
			@methods = {} # [meth_sym, arity] => # [[type, impl. class/mod, types of first arg or nil, real arity], ...]
			@function_names = {} # [meth_sym, arity] => name # initialized on first use
			builtins.each { |builtin|
				(METHODS[builtin] + COMMON_METHODS).each { |arr|
					(@methods[arr[0, 2]] ||= []) << [builtin, arr[2] || builtin, arr[3], arr[4] || arr[1]]
				}
			}
			compiler.add_preprocessor(:call) { |cfun, node|
				handle_call(cfun, node.last, node)
			}
		end

		def deduce_type(node)
			if Array === node
				case node.first
				when :lit
					node.last[:lit].class.name.to_sym
				when :nil
					:NilClass
				when :false
					:FalseClass
				when :true
					:TrueClass
				when :str, :dstr
					:String
				when :dsym
					:Symbol
				when :array, :zarray
					:Array
				when :hash
					:Hash
				when :dregx, :dregx_once
					:Regexp
				else
					nil
				end
			else
				nil
			end
		end

		def get_function(method, arity, recv_type)
			mat = [method, arity, recv_type]
			if (fn = function_names[mat])
				fn
			elsif (meth_list = methods[[method, arity]])
				if recv_type
					if meth_list.find { |arr| arr.first == recv_type }
						function_names[mat] = "#{METHOD_NAME_MAPPINGS[method]}__#{arity}_#{recv_type}"
					else
						nil # we can't optimize this recv_type/method combination
					end
				else
					function_names[mat] = "#{METHOD_NAME_MAPPINGS[method]}__#{arity}"
				end
			else
				nil
			end
		end

		def handle_call(cfun, hash, node)
			args = []
			if hash[:args]
				if hash[:args].first == :array
					args = hash[:args].last
				else
					return node
				end
			end
			if (fun = get_function(hash[:mid], args.size, deduce_type(hash[:recv])))
				cfun.instance_eval {
					recv = comp(hash[:recv])
					if args.empty?
						"#{fun}(#{recv})"
					else
						c_scope_res {
							l "VALUE recv = #{recv};"
							build_c_arr(args, "argv")
							"#{fun}(recv, argv)"
						}
					end
				}
			else
				node
			end
		end

		METHOD_LOOKUP_CODE = %{
			static BUILTINOPT_FP builtinopt_method_lookup(VALUE klass, VALUE origin, ID mid, long arity) {
				NODE *body;
				while (klass != origin) {
					if (TYPE(klass) == T_ICLASS && RBASIC(klass)->klass == origin) break;
					if (st_lookup(RCLASS(klass)->m_tbl, mid, (st_data_t *)&body)) return NULL;
					klass = RCLASS(klass)->super;
					if (!klass) return NULL;
				}
				if (st_lookup(RCLASS(klass)->m_tbl, mid, (st_data_t *)&body)) {
					body = body->nd_body;
					if (nd_type(body) == NODE_FBODY) body = body->nd_head;
					if (nd_type(body) == NODE_CFUNC && body->nd_argc == arity) {
						return body->nd_cfnc;
					}
				}
				return NULL;
			}
		}

		def global_c_code
			unless function_names.empty?
				res = []
				res << "typedef VALUE (*BUILTINOPT_FP)(ANYARGS);"
				res << METHOD_LOOKUP_CODE
				function_names.sort_by { |mat, name| name }.each { |mat, name|
					method_sym, arity, recv_type = *mat
					meth_list = methods[[method_sym, arity]]
					if recv_type
						meth_list = [meth_list.find { |arr| arr.first == recv_type }]
					end
					res << "static VALUE #{name}(VALUE recv#{arity > 0 ? ", VALUE *argv" : ""}) {"
					res << "static BUILTINOPT_FP method_tbl[#{meth_list.size}];"
					res << "static int lookup_done = 0;"
					res << "if (!lookup_done) {"
					res << "lookup_done = 1;"
					meth_list.each_with_index { |m, i|
						lookup_args = [BUILTIN_C_VAR_MAP[m[0]], BUILTIN_C_VAR_MAP[m[1]], compiler.sym(method_sym), m[3]]
						res << "method_tbl[#{i}] = builtinopt_method_lookup(#{lookup_args.join(", ")});"
					}
					res << "}"
					res << "switch(TYPE(recv)) {" unless recv_type
					meth_list.each_with_index { |m, i|
						res << "case #{BUILTIN_TYPE_MAP[m[0]]}:" unless recv_type
						check =
							if recv_type || NO_CLASS_CHECK_BUILTINS.include?(m[0])
								"method_tbl[#{i}]"
							else
								"method_tbl[#{i}] && CLASS_OF(recv) == #{BUILTIN_C_VAR_MAP[m[0]]}"
							end
						call =
							if m[3] == -1
								"(*(method_tbl[#{i}]))(#{arity}, #{arity > 0 ? "argv" : "NULL"}, recv)"
							else
								args = (0...arity).map { |j| "argv[#{j}]" }.join(", ")
								args = ", " + args unless args.empty?
								"(*(method_tbl[#{i}]))(recv#{args})"
							end
						if (other = m[2])
							if arity != 1
								raise Ruby2CExtension::Ruby2CExtError::Bug, "arity must be 1 for arg type check"
							end
							res << "switch(TYPE(argv[0])) {"
							res << other.map { |o| "case #{BUILTIN_TYPE_MAP[o]}:" }.join("\n")
							res << "if (#{check}) return #{call};"
							res << "default:"
							res << (recv_type ? ";" : "goto std_call;")
							res << "}"
						else
							res << "if (#{check}) return #{call};"
							res << "else goto std_call;" unless recv_type
						end
					}
					res << "default:\nstd_call:" unless recv_type
					res << "return rb_funcall3(recv, #{compiler.sym(method_sym)}, #{arity}, #{arity > 0 ? "argv" : "0"});"
					res << "}" unless recv_type
					res << "}"
				}
				res.join("\n")
			end
		end

	end

end