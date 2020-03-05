require 'fileutils'
module Api
  module Tools
    class Remove < Versioning
      def apply
        %w[dirs files routes].each do |apply|
          send(apply)
        end
      end

      def routes
        file_name = "config/routes.rb"
        text = File.read(file_name)
        text = text.gsub("#{@dot_new}", "#{@dot_prev}")
        text = text.gsub("draw(:v#{@version})", '')

        write(file_name, text)
      end

      def dirs
        %w[app/controllers/api spec/requests/api].each do |dir|
          path = dir.match('requests') ? "#{dir}/v#{@dot_new}" : "#{dir}/v#{@version}"
          FileUtils.rm_rf(path)
        end
      end

      def files
        ["app/controllers/api/v#{@version}.rb", "config/routes/v#{@version}.rb", "public/doc/openapi-3-v#{@dot_new}.json"].each_with_index do |file, index|
          FileUtils.rm(file)
        end
      end
    end
  end
end
