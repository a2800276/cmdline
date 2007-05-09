require 'cmdline'

	cmdline=CommandLine.new [
		["-f", "-flag", :starts_with_a_digit, "value", true, nil, "must start with a number", /^\d.*/]
	]

	cmdline.parse ARGV
	puts cmdline.starts_with_a_digit	

