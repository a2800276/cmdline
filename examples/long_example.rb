require 'cmdline'

if $0 == __FILE__

commands_doc= <<ENDDOC

Available commands:
  add
  blame
  cat
  checkout

ENDDOC

args_doc = "files to process"
commands_check= ["add", "blame", "cat", "checkout"]

file_readable=lambda{|f| File.readable? f}
		

cmdline=CommandLine.new [
	[:command, nil, :command, "command", false, "add", commands_doc, commands_check],
	["-o", nil, :outfile, "file", false, STDOUT, "filename to write output to, default STDOUT"],
	["-i", "--infile", :infile, "file",  false, STDIN, "filename to read from, default STDIN", file_readable],
	["-v", "--verbose", :verbose, false,  false, nil, "verbose"],
	["-n", "--numeric", :number, "num",  true, nil, "numeric value", /^\d+$/],
	[:args, nil, :args, "args", false, nil, args_doc, file_readable]
]

cmdline.parse ARGV
puts cmdline.outfile
puts cmdline.command
puts cmdline.args
end
