class Gitcycle < Thor
  class Config
    class <<self
      
      @@config = {}

      def method_missing(method, *args, &block)
        method = method.to_s
        if method[-1..-1] == "="
          @@config[method[0..-2]] = args.first
        else
          @@config[method]
        end
      end

      def read
        if File.exists?(config_path)
          @@config = YAML.load(File.read(config_path))
        else
          @@config = {}
        end
      end

      def write
        FileUtils.mkdir_p(File.dirname(config_path))
        File.open(config_path, 'w') do |f|
          f.write(YAML.dump(@@config))
        end
      end
    end
  end
end