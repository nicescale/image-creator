require 'mcollective'
require 'shellwords'

module FP
  class Util
    class << self
      def sh(args, timeout = nil)
        timeout ||= Config.instance.cmd_timeout
        stdout = ''
        stderr = ''
        options = {
          stdout: stdout,
          stderr: stderr,
          timeout: timeout
        }
        cmd = Shellwords.join(Array(args))
        status = MCollective::Shell.new(cmd, options).runcommand
        {
          stdout: stdout,
          stderr: stderr,
          status: status.exitstatus,
        }
      end
    end
  end
end
