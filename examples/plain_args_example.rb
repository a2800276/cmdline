require 'cmdline'

args_doc = "files to process"		
file_readable=lambda{|f| File.readable? f}
cmdline=CommandLine.new [
	[:args, nil, :args, "args", true, nil, args_doc, file_readable]
]
cmdline.parse ARGV
puts cmdline.args

