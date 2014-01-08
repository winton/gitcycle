module Gitcycle
  class Git
    module Command
      
      def errored?(output)
        output.include?("fatal: ") ||
        output.include?("ERROR: ") ||
        $?.exitstatus != 0
      end

      def git(cmd, options={})
        Log.log(:git_cmd, cmd)

        output = `git #{cmd} 2>&1`

        Log.log(:git_output, output)

        if !options[:force] && errored?(output)
          git_fail(cmd, output)
        end

        output
      end

      def git_fail(cmd, output)
        Log.log(:git_failure)

        puts "Failed: git #{cmd}".red.space
        puts output.gsub(/^/, "  ")

        puts ""
        exit 1
      end
    end
  end
end