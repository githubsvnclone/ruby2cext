
require "ruby2cext/str_to_c_strlit"
require "ruby2cext/error"
require "ruby2cext/tools"
require "ruby2cext/common_node_comp"
require "ruby2cext/scopes"

module Ruby2CExtension

	module CFunction
		# contains all different Types of C functions that are compiled from ruby nodes

		class Base
			include CommonNodeComp
			extend Tools::EnsureNodeTypeMixin
			attr_reader :scope, :compiler, :closure_tbl
			attr_accessor :need_res, :need_self, :need_cref, :need_class, :need_wrap
			def initialize(compiler, scope)
				@compiler = compiler
				@scope = scope
				@closure_tbl = []
				@scope.closure_tbl = @closure_tbl
				@lines = []
				@while_stack = []
			end

			# some redirects to compiler
			def un(str); compiler.un(str); end
			def sym(sym); compiler.sym(sym); end
			def global(str); compiler.global(str); end
			def add_helper(str); compiler.add_helper(str); end

			def get_lines
				@lines.join("\n")
			end
			def l(line) # add_line
				# ignore lines with only whitespace or only alnum chars (variable name)
				unless line =~ /\A\s*\z/ || (line =~ /\A(\w*);?\z/ && !(%w[break continue].include? $1))
					@lines << line
				end
			end

			def push_while(redo_lbl, next_lbl, break_lbl)
				@while_stack << [redo_lbl, next_lbl, break_lbl]
			end
			def pop_while
				raise Ruby2CExtError::Bug, "popped from empty while stack" if @while_stack.empty?
				@while_stack.pop
			end
			def in_while?(lbl_type)
				return false if @while_stack.empty?
				case lbl_type
				when :redo
					@while_stack.last[0]
				when :next
					@while_stack.last[1]
				when :break
					@while_stack.last[2]
				else
					false
				end
			end

			def in_block?(lbl_type = nil)
				false
			end

			def return_allowed?
				false # subclass
			end

			def need_closure_ptr
				false # only needed in Block
			end

			def assign_res(str)
				self.need_res = true
				unless str.strip == "res"
					l "res = #{str};"
				end
			end
			def get_self
				self.need_self = true
				"self"
			end
			def get_cref
				self.need_cref = true
				get_cref_impl # subclass
			end
			def get_class
				self.need_class = true
				"s_class"
			end
			def get_cbase
				"(#{get_cref}->nd_clss)"
			end
			def get_cvar_cbase
				# there is always at least one real class in the cref chain
				add_helper <<-EOC
					static VALUE cvar_cbase(NODE *cref) {
						while (FL_TEST(cref->nd_clss, FL_SINGLETON)) { cref = cref->nd_next; }
						return cref->nd_clss;
					}
				EOC
				"cvar_cbase(#{get_cref})"
			end

			def get_closure_ary_var
				"my_closure_ary"
			end

			def get_wrap_ptr
				"(&the_wrap)"
			end

			def add_closure_need(sym)
				closure_tbl << sym unless closure_tbl.include? sym
			end

			def closure_buid_c_code
				if closure_tbl.empty?
					nil
				else
					res = ["#{get_closure_ary_var} = rb_ary_new2(#{closure_tbl.size});"]
					closure_tbl.each_with_index { |entry, idx|
						case entry
						when Integer
							res << "RARRAY(#{get_closure_ary_var})->ptr[#{idx}] = #{scope.get_dvar_ary(entry)};"
						when :lvar
							res << "RARRAY(#{get_closure_ary_var})->ptr[#{idx}] = #{scope.get_lvar_ary};"
						when :self
							res << "RARRAY(#{get_closure_ary_var})->ptr[#{idx}] = #{get_self};"
						when :class
							res << "RARRAY(#{get_closure_ary_var})->ptr[#{idx}] = #{get_class};"
						when :cref
							add_helper <<-EOC
								static void cref_data_mark(NODE *n) {
									rb_gc_mark((VALUE)n);
								}
							EOC
							res << "RARRAY(#{get_closure_ary_var})->ptr[#{idx}] = " +
								"Data_Wrap_Struct(rb_cObject, cref_data_mark, 0, #{get_cref});"
						else
							raise Ruby2CExtError::Bug, "unexpected closure_tbl entry: #{entry.inspect}"
						end
					}
					res << "RARRAY(#{get_closure_ary_var})->len = #{closure_tbl.size};"
					res.join("\n")
				end
			end

			def wrap_buid_c_code
				add_helper <<-EOC
					struct wrap {
						VALUE self;
						VALUE s_class;
						NODE *cref;
						VALUE my_closure_ary;
						VALUE *closure;
						VALUE *var;
						long state;
					};
				EOC
				res = []
				res << "the_wrap.self = #{get_self};" if need_self
				res << "the_wrap.s_class = #{get_class};" if need_class
				res << "the_wrap.cref = #{get_cref};" if need_cref
				res << "the_wrap.my_closure_ary = #{get_closure_ary_var};" unless closure_tbl.empty?
				res << "the_wrap.closure = closure;" if need_closure_ptr
				res << "the_wrap.var = #{scope.var_ptr_for_wrap};" if scope.var_ptr_for_wrap
				res.compact.join("\n")
			end

			def init_c_code
				cb_c_code = closure_buid_c_code # must be called before the rest because it might change self or scope
				res = []
				res << "VALUE res;" if need_res
				res << "VALUE s_class = (#{get_cref})->nd_clss;" if need_class
				res << "VALUE #{get_closure_ary_var};" if cb_c_code
				res << "struct wrap the_wrap;" if need_wrap
				res << scope.init_c_code
				res << cb_c_code if cb_c_code
				res << wrap_buid_c_code if need_wrap
				res.compact.join("\n")
			end
		end

		class ClassModuleScope < Base
			def self.compile(outer, scope_node, class_mod_var)
				ensure_node_type(scope_node, :scope)
				cf = self.new(outer.compiler, Scopes::Scope.new(scope_node.last[:tbl]))
				fname = cf.un("class_module_scope")
				cf.instance_eval {
					block = make_block(scope_node.last[:next])
					l "return #{comp(block)};"
				}
				body = "#{cf.init_c_code}\n#{cf.get_lines}"
				args = []
				args << "VALUE self" if cf.need_self
				args << "NODE *cref" if cf.need_cref
				sig = "static VALUE #{fname}(#{args.join(", ")}) {"
				cf.compiler.add_fun("#{sig}\n#{body}\n}")
				outer.instance_eval {
					args = []
					args << class_mod_var if cf.need_self
					args << "NEW_NODE(NODE_CREF, #{class_mod_var}, 0, #{get_cref})" if cf.need_cref
					assign_res("#{fname}(#{args.join(", ")})")
				}
				"res"
			end

			def get_cref_impl
				"cref"
			end

		end

		class ToplevelScope < ClassModuleScope
			def self.compile(compiler, scope_node)
				ensure_node_type(scope_node, :scope)
				cf = self.new(compiler, Scopes::Scope.new(scope_node.last[:tbl], true))
				fname = cf.un("toplevel_scope")
				cf.instance_eval {
					block = make_block(scope_node.last[:next])
					l "#{comp(block)};"
				}
				body = "#{cf.init_c_code}\n#{cf.get_lines}"
				sig = "static void #{fname}(VALUE self, NODE *cref) {"
				cf.compiler.add_fun("#{sig}\n#{body}\n}")
				fname
			end
		end

		class Method < Base
			def self.compile(outer, scope_node, def_fun, class_var, mid)
				ensure_node_type(scope_node, :scope)
				cf = self.new(outer.compiler, Scopes::Scope.new(scope_node.last[:tbl]))
				fname = cf.un("method")
				cf.instance_eval {
					block = [:block, make_block(scope_node.last[:next]).last.dup] # dup the block to allow modification
					arg = block.last.shift
					ba = nil
					unless block.last.empty? || block.last.first.first != :block_arg
						ba = block.last.shift
					end
					handle_method_args(arg, ba)
					l "return #{comp(block)};"
				}
				body = "#{cf.init_c_code}\n#{cf.get_lines}"
				sig = "static VALUE #{fname}(int argc, VALUE *argv, VALUE self) {"
				cf.compiler.add_fun("#{sig}\n#{body}\n}")
				if cf.need_cref
					outer.instance_eval {
						add_helper <<-EOC
							static void def_only_once(ID mid) {
								rb_raise(rb_eTypeError, "def for \\"%s\\" can only be used once", rb_id2name(mid));
							}
						EOC
						c_scope {
							l "static int done = 0;"
							l "if (done) def_only_once(#{sym(mid)});"
							l "#{cf.cref_global_var} = (VALUE)(#{get_cref});"
							l "done = 1;"
							l "#{def_fun}(#{class_var}, #{mid.to_s.to_c_strlit}, #{fname}, -1);"
						}
					}
				else
					outer.instance_eval {
						l "#{def_fun}(#{class_var}, #{mid.to_s.to_c_strlit}, #{fname}, -1);"
					}
				end
				"Qnil"
			end

			def return_allowed?
				true
			end

			def get_cref_impl
				@cref_global_var ||= global("Qfalse")
				"(RNODE(#{@cref_global_var}))"
			end
			attr_reader :cref_global_var
		end

		class Block < Base
			def self.compile(outer, block_node, var_node)
				ensure_node_type(block_node, :block)
				cf = self.new(outer.compiler, outer.scope.new_dyna_scope)
				fname = cf.un("block")
				cf.instance_eval {
					if Array === var_node
						if var_node.first == :masgn
							dup_hash = var_node.last.dup
							c_if("ruby_current_node->nd_state != 1") { # 1 is YIELD_FUNC_AVALUE
								# do "svalue_to_mrhs"
								c_if("bl_val == Qundef") {
									l "bl_val = rb_ary_new2(0);"
								}
								c_else {
									#if dup_hash[:head] # TODO
										l "VALUE tmp = rb_check_array_type(bl_val);"
										l "bl_val = (NIL_P(tmp) ? rb_ary_new3(1, bl_val) : tmp);"
									#else
									#	l "bl_val = rb_ary_new3(1, bl_val);"
									#end
								}
							}
							dup_hash[:value] = "bl_val"
							comp_masgn(dup_hash)
						else
							c_if("ruby_current_node->nd_state == 1") { # 1 is YIELD_FUNC_AVALUE
								# do "avalue_to_svalue"
								l "if (RARRAY(bl_val)->len == 0) bl_val = Qnil;"
								l "else if (RARRAY(bl_val)->len == 1) bl_val = RARRAY(bl_val)->ptr[0];"
							}
							handle_assign(var_node, "bl_val")
						end
					end
					l "block_redo:"
					l "return #{comp_block(block_node.last)};"
				}
				body = "#{cf.init_c_code(outer)}\n#{cf.get_lines}"
				sig = "static VALUE #{fname}(VALUE bl_val, VALUE closure_ary, VALUE bl_self) {"
				cf.compiler.add_fun("#{sig}\n#{body}\n}")
				[fname, cf.need_closure_ptr]
			end

			def init_c_code(outer)
				cb_c_code = closure_buid_c_code # must be called before the rest because it might change self or scope
				outer.add_closure_need(:self) if need_self
				outer.add_closure_need(:class) if need_class
				outer.add_closure_need(:cref) if need_cref
				res = []
				res << "VALUE res;" if need_res
				if need_closure_ptr
					res << "VALUE *closure = RARRAY(closure_ary)->ptr;"
				end
				res << "VALUE self = (bl_self == Qundef ? closure[#{outer.closure_tbl.index(:self)}] : bl_self);" if need_self
				res << "VALUE s_class = (bl_self == Qundef ? closure[#{outer.closure_tbl.index(:class)}] : ruby_class);" if need_class
				if need_cref
					# see #define Data_Get_Struct
					res << "NODE *cref = (Check_Type(closure[#{outer.closure_tbl.index(:cref)}]," +
						" T_DATA), (NODE*)DATA_PTR(closure[#{outer.closure_tbl.index(:cref)}]));"
				end
				res << "VALUE #{get_closure_ary_var};" if cb_c_code
				res << "struct wrap the_wrap;" if need_wrap
				res << scope.init_c_code
				res << cb_c_code if cb_c_code
				res << wrap_buid_c_code if need_wrap
				res.compact.join("\n")
			end

			def in_block?(lbl_type = nil)
				case lbl_type
				when :redo
					"block_redo"
				else
					true
				end
			end

			def need_closure_ptr
				scope.need_closure || need_self || need_class || need_cref
			end

			def get_cref_impl
				"cref"
			end
		end

		class Wrap < Base

			def self.compile(outer, fname)
				cf = self.new(outer)
				cf.l "return #{yield cf};"
				body = "#{cf.init_c_code}\n#{cf.get_lines}"
				sig = "static VALUE #{fname}(struct wrap *wrap_ptr) {"
				cf.compiler.add_fun("#{sig}\n#{body}\n}")
				outer.need_wrap = true
				nil
			end

			attr_reader :base_cfun

			# the following attr_accessors from Base are redefined, to redirect to base_cfun
			[:need_self, :need_cref, :need_class, :need_wrap].each { |a|
				define_method(a) { base_cfun.send(a) }
				asgn_sym = :"#{a}="
				define_method(asgn_sym) { |arg| base_cfun.send(asgn_sym, arg) }
			}

			def initialize(cfun_to_wrap)
				if Wrap === cfun_to_wrap
					@base_cfun = cfun_to_wrap.base_cfun
				else
					@base_cfun = cfun_to_wrap
				end
				@compiler = base_cfun.compiler
				@scope = Scopes::WrappedScope.new(base_cfun.scope)
				@closure_tbl = base_cfun.closure_tbl
				@lines = []
				@while_stack = []
			end

			# TODO: def in_while?(lbl_type), so that it also checks in base_cfun ...

			def in_block?(lbl_type = nil)
				# TODO: ask base_cfun ...
				false
			end

			def return_allowed?
				# TODO: ask base_cfun ...
				false # subclass
			end

			def get_self
				self.need_self = true
				"(wrap_ptr->self)"
			end
			def get_cref_impl
				"(wrap_ptr->cref)"
			end
			def get_class
				self.need_class = true
				"(wrap_ptr->s_class)"
			end

			def get_closure_ary_var
				"(wrap_ptr->my_closure_ary)"
			end

			def get_wrap_ptr
				"wrap_ptr"
			end

			[:closure_buid_c_code, :wrap_buid_c_code, :need_closure_ptr].each { |m|
				define_method(m) {
					raise Ruby2CExtError::Bug, "the method #{m} may not be called for an instance of Wrap"
				}
			}

			def init_c_code
				res = []
				res << "VALUE res;" if need_res
				res.compact.join("\n")
			end
		end

	end

end