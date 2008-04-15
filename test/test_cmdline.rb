require 'test/unit'
require File.dirname(__FILE__) + '/../lib/cmdline.rb'

class TestCmdline < Test::Unit::TestCase
  def setup

  end

  def test_one_arg
    args = ["a_single_args"]
    cmd = [
      [ :args, nil, :args, "whatever", true, nil, "test" ],
    ]

    cmdline = CommandLine.new cmd
    cmdline.exit_on_usage=false
    assert_nothing_raised {
      cmdline.parse args
    }

  end
end
