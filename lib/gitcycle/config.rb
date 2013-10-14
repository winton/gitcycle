class Gitcycle < Thor
  class Config
    class <<self
      
      attr_accessor :config
      attr_accessor :config_path
      attr_accessor :git_login
      attr_accessor :git_repo
      attr_accessor :git_url

      def load
        unless self.config_path
          self.config_path = ENV['CONFIG'] || "~/.gitcycle.yml"
          self.config_path = File.expand_path(config_path)
        end
        read
      end

      def method_missing(method, *args, &block)
        raise "Call Config.read first"  unless config
        
        method = method.to_s
        
        if method[-1..-1] == "="
          method = method[0..-2]
          config[method] = args.first
          write
        end
        
        config[method]
      end

      def read
        if File.exists?(config_path)
          self.config = YAML.load(File.read(config_path))
        else
          self.config = {}
        end
      end

      def write
        FileUtils.mkdir_p(File.dirname(config_path))
        File.open(config_path, 'w') do |f|
          f.write(YAML.dump(config))
        end
      end
    end
  end
end