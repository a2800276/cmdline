

class CommandLine

	FLAG_1=0
	FLAG_2=1
	ACCESSOR=2	
	DISP_NAME=3
	REQUIRED=4
	DEFAULT=5
	DOC=6
	CHECK=7

	@@add_help=true



	def self.add_help= bool
		@@add_help=bool
	end



	# definition
	# [ :command, nil, <accessor>, <display name>, <required?>, <default>, <doc>, <check allowed commands> ]
	# 	command is a subcommand, cf. `svn help`, 
	# [ <flag1>, <flag2/nil>, <accessor>, <display name>, <required?>, <default>, <doc>, <check: optional> ]
	#
	# commandline taking arguments, e.g. `mv src target` are specified like this:
	# [ :args, nil, <accessor>, <display name>, <required>, <default>, <doc>, <check: optional> ]
	# the entire rest of the commandline arg array after the first unrecognized options
	# will then be available under `cmdline.<accessor>` the check proc will either be able to check the entire
	# array or, if that fails with an exception, will test each element individually.
	def initialize definition
		self.definition= definition
		@output_io ||= STDERR
		@exit_on_usage=true

	end

	def output= io
		@output_io = io
	end

	# whether `exit` will be called to terminate the program if `usage` is
	# called. Default behaviour is to call `exit`
	# If this behaviour is turned off, a call to usage will result in an exception
	# instead.
	def exit_on_usage= bool
		@exit_on_usage= bool
	end

	def definition= definition
		definition.push(["-h", "--help", :help, false,  false, nil, "print this message"]) if @@add_help
		cl = class << self; self; end
		# add an accessor to self for each definition.
		cl.instance_eval { attr_accessor *definition.map{|arg_def| arg_def[ACCESSOR]} }
		

		definition.each {|arg_def|
			#check if cmdline takes a command
			if arg_def[FLAG_1]==:command
				@has_command = true
			end
			#set default values
			set arg_def[ACCESSOR], arg_def[DEFAULT]
		}

		@definition=definition

		class << @definition
			def retrieve_flag flag
				find { |arg|
					arg[FLAG_1]==flag || arg[FLAG_2]==flag
				}
			end
		end

	end # definition

	def usage mes=""
		raise mes unless @exit_on_usage

		
		# put together usage information for flags.	
		max = 0			#max flag length for formatting
		has_required=false
		has_options=false
		us = @definition.map {|arg_def|
			if arg_def[FLAG_1] == :command 
				flag=:command
			elsif arg_def[FLAG_1] == :args
				flag=:args	
			else
		# create a usage string of the form:
		#   -f/-flag <value>* must start with a number
		# for each definition. (commands and args are treated seperately)		
				flag = "#{arg_def[FLAG_1]}"
				flag << "/#{arg_def[FLAG_2]}" if arg_def[FLAG_2]
				flag << " <#{arg_def[DISP_NAME]}>" if arg_def[DISP_NAME]
				flag << "*" if arg_def[REQUIRED]
				has_required = true if arg_def[REQUIRED]
				has_options = true
				max = max > flag.length ? max : flag.length
			end
			[flag, arg_def[DOC]]
		}
		
		usage = "usage: #{$0}"
		
		if command=@definition.retrieve_flag(:command)
			fmt = command[REQUIRED] ? " %s" : " [%s]"
			usage << sprintf(fmt,command[DISP_NAME])
		end
		
		if has_options
			usage << (has_required ? " options" : " [options]")
		end
		
		args_doc=false
		if command=@definition.retrieve_flag(:args)
			fmt = command[REQUIRED] ? " %s" : " [%s]"
			usage << sprintf(fmt,command[DISP_NAME])
			args_doc = "#{command[DISP_NAME]}: #{command[DOC]}"
		end
		usage << "\n"

		us.each { |arg_def|
			if arg_def[0].kind_of? String
				usage << sprintf("  %-#{max}s %s\n", arg_def[0], arg_def[1]) 
			elsif arg_def[0] == :command
				# command 
				usage << arg_def[1] if arg_def[1] 
			end

		}
		@output_io.puts usage
		@output_io.puts "* required flags" if has_required
		@output_io.puts "\n#{args_doc}" if args_doc
		@output_io.puts
		@output_io.puts mes
		exit 
	end

	def parse args=ARGV
		@found = []
		i=0
		# handle svn like command
		if definition = @definition.retrieve_flag(:command)

			if definition[REQUIRED] && args.length==0
				usage "missing mandatory command"
			elsif test_def = @definition.retrieve_flag(args[i])
				usage "missing mandatory command" if definition[REQUIRED] 
			else
			
				check definition, args[i]
				set definition[ACCESSOR], args[i]

				i+=1
			end	
				
		end

		while i<args.length do
			@found.push args[i]
			if definition = @definition.retrieve_flag(args[i]) # is there a definition for this flag?
				if definition[DISP_NAME]
					# takes a parameter
					check definition, args[i+=1]
					set definition[ACCESSOR], args[i]	
				else
					# plain flag
					set definition[ACCESSOR], true
				end	
			else	# are unknown flags ok? i.e. is there an :args definition.
				if definition = @definition.retrieve_flag(:args)
					check_args definition, args[i, args.length-1]
					set definition[ACCESSOR], args[i, args.length-1]
					break
				end
				usage "unknown flag: #{args[i]}"
			end
			i+=1
		end

		if definition = @definition.retrieve_flag(:args) # are :args required?
			if definition[REQUIRED]
				args = self.send definition[ACCESSOR]
				usage "missing mandatory args" unless args && args.length>1
			end
		end
		
		usage if self.help # call usage if the -h/--help flag was set.

		# check all mandatory args are present.
		@definition.each {|definition|

			if definition[REQUIRED] && !([:command, :args].include? definition[FLAG_1])
				usage "missing mandatory flag #{definition [FLAG_1]?definition[FLAG_1]:definition[FLAG_2]}" unless ((@found.include? definition[FLAG_1]) || (@found.include? definition[FLAG_2]))
			end
		}
	end

	private

	def set sym, value
		self.send((sym.to_s+"=").to_sym, value)
	end
	
	#
	# check the argument's value against allowed values,
	# check may be a Regexp, an Array or a Proc taking the value.
	#
	def check definition, val
		check=definition[CHECK]
		return true unless check 
		if check.kind_of? Regexp
			if !check.match val
				usage "illegal value: #{val} for: #{definition[FLAG_1]}"
			end
		elsif check.kind_of? Proc
			usage "illegal value: #{val} for: #{definition[FLAG1]}" unless definition[CHECK].call val
		elsif check.kind_of? Array
			usage "illegal value: #{val} for: #{definition[FLAG1]}" unless definition[CHECK].include? val
		end

		return true
	end

	def check_args definition, arr
		ret = false
		# might be a proc to check the entire array
		if definition[CHECK].kind_of? Proc 
			begin
				return definition[CHECK].call(arr)
			rescue
			end
		end
		# or something else to check each arg against
		unless ret
			arr.each {|val|
				ret= check definition, val
				return false unless ret
			}
		end
		return ret
	end

end

