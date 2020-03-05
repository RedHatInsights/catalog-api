require 'fileutils'
module Api
  module Tools
    class Add < Versioning
      def apply
        %w[dirs files new_routes draw_file server_names].each do |apply|
          self.send(apply)
        end
      end

      def server_names
        file_name = "public/doc/openapi-3-v#{@dot_new}.json"
        text = File.read(file_name)
        text = text.gsub("/api/catalog/v#{@dot_prev}","/api/catalog/v#{@dot_new}")

        write(file_name, text)
      end

      def new_routes
        file_name = "config/routes.rb"
        text = File.read(file_name)
        text = text.gsub("draw(:v#{@previous})", "draw(:v#{@previous})\n    draw(:v#{@version})")
        text = text.gsub("v#{@dot_prev}","v#{@dot_new}")

        write(file_name, text)
      end

      def draw_file
        file_name = "config/routes/v#{@version}.rb"
        text = File.read(file_name)
        text = text.gsub("#{@previous}", "#{@version}")
        text = text.gsub("v#{@dot_prev}", "v#{@dot_new}")

        write(file_name, text)
      end

      def dirs
        # build new dirs
        %w[app/controllers/api spec/requests/api].each do |dir|
          path = dir.match('requests') ? "#{dir}/v#{@dot_new}" : "#{dir}/v#{@version}"
          raise StandardError.new("Path already exists") if check_existing?(path)
          FileUtils.mkdir(path)
        end
      end

      def files
        prev = ["app/controllers/api/v#{@previous}.rb", "config/routes/v#{@previous}.rb", "public/doc/openapi-3-v#{@dot_prev}.json"]
        ["app/controllers/api/v#{@version}.rb", "config/routes/v#{@version}.rb", "public/doc/openapi-3-v#{@dot_new}.json"].each_with_index do |file, index|
          raise StandardError.new("File already exists") if check_existing?(file)
          FileUtils.cp(prev[index], file)
        end
      end
    end
  end
end
