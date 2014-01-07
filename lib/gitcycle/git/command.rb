module Gitcycle
  class Git
    module Command
      
      def errored?(output)
        output.include?("fatal: ") ||
        output.include?("ERROR: ") ||
        $?.exitstatus != 0
      end

      def git(cmd, options={})
        log("> ".green + cmd)

        output = `git #{cmd} 2>&1`
        log(output)

        if !options[:force] && errored?(output)
          git_fail(cmd)
        end

        output
      end

      def git_fail(cmd)
        puts "Failed: git #{cmd}".red.space
        puts log.last.gsub(/^/, "  ")
        puts ""

        begin; raise; rescue => e
          puts e.backtrace.join("\n  ")
        end

        puts ""
        exit 1
      end
    end
  end
end