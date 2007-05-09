require 'cmdline'

doc= <<END_DOC
    build            Build a gem from a gemspec
    cert             Adjust RubyGems certificate settings
    check            Check installed gems
    cleanup          Clean up old versions of installed gems in the local
                     repository
    contents         Display the contents of the installed gems
    ...
END_DOC


command_arr=["build", "cert", "check", "cleanup", "contents"] # ...
cmdline=CommandLine.new [
	[:command, nil, :command, "command", false, "add", doc, command_arr]
]
cmdline.parse ARGV
puts cmdline.command

