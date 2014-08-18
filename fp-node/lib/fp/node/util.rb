require 'mcollective'
require 'shellwords'

module FP
  class Util
    class << self
      def sh(args, timeout = nil)
        timeout ||= Config.instance.cmd_timeout.to_i
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

      def run_in_background(*args)
        cmd = Shellwords.join(Array(args))
        pid = Process.spawn(cmd, out: '/dev/null', err: '/dev/null')
        Process.detach(pid)
      end
    end
  end
end
