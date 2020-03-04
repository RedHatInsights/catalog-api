require 'fileutils'
module Api
  module Tools
    class Versioning
      def self.build_new(new_version, previous_version)
        add = new(new_version, previous_version)
        add.build_dirs
        add.build_files
        add.append_new_routes
        add.append_draw_file
      end

      def self.remove(version, previous)
        remove = new(version, previous)
        remove.rm_dirs
        remove.rm_files
        remove.remove_routes
      end

      def initialize(version, previous)
        @version = version
        @previous = previous
        @dot_prev = @previous.split('x').join('.')
        @dot_new = @version.split('x').join('.')
      end

      def append_new_routes
        file_name = "config/routes.rb"
        text = File.read(file_name)
        text = text.gsub("draw(:v#{@previous})", "draw(:v#{@previous})\n    draw(:v#{@version})")
        text = text.gsub("v#{@dot_prev}","v#{@dot_new}")

        write(file_name, text)
      end

      def append_draw_file
        file_name = "config/routes/v#{@version}.rb"
        text = File.read(file_name)
        text = text.gsub("#{@previous}", "#{@version}")
        text = text.gsub("v#{@dot_prev}", "v#{@dot_new}")

        write(file_name, text)
      end

      def remove_routes
        file_name = "config/routes.rb"
        text = File.read(file_name)
        text = text.gsub("#{@dot_new}", "#{@dot_prev}")
        text = text.gsub("draw(:v#{@version})", '')

        write(file_name, text)
      end

      def rm_dirs
        %w[app/controllers/api spec/requests/api].each do |dir|
          path = dir.match('requests') ? "#{dir}/v#{@dot_new}" : "#{dir}/v#{@version}"
          FileUtils.rm_rf(path)
        end
      end

      def rm_files
        ["app/controllers/api/v#{@version}.rb", "config/routes/v#{@version}.rb", "public/doc/openapi-3-v#{@dot_new}.json"].each_with_index do |file, index|
          FileUtils.rm(file)
        end
      end

      def build_dirs
        # build new dirs
        %w[app/controllers/api spec/requests/api].each do |dir|
          path = dir.match('requests') ? "#{dir}/v#{@dot_new}" : "#{dir}/v#{@version}"
          raise StandardError.new("Path already exists") if check_existing?(path)
          FileUtils.mkdir(path)
        end
      end

      def build_files
        prev = ["app/controllers/api/v#{@previous}.rb", "config/routes/v#{@previous}.rb", "public/doc/openapi-3-v#{@dot_prev}.json"]
        ["app/controllers/api/v#{@version}.rb", "config/routes/v#{@version}.rb", "public/doc/openapi-3-v#{@dot_new}.json"].each_with_index do |file, index|
          raise StandardError.new("File already exists") if check_existing?(file)
          FileUtils.cp(prev[index], file)
        end
      end

      private

      def write(file_name, text)
        File.open(file_name, "w") do |file|
          file.puts text
        end
      end

      def check_existing?(file_path)
        FileUtils.cd(file_path)
        true
      rescue Errno::ENOENT
        false
      end
    end
  end
end
