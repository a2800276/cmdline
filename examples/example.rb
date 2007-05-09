require 'cmdline'

	cmdline=CommandLine.new [
		["-m", "-message", :message, "message", true, nil, "message for 'usage'"]
	]

	cmdline.parse ARGV
	puts cmdline.message	

