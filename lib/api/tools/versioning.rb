require 'fileutils'
module Api
  module Tools
    class Versioning
      def self.build_new(new_version, previous_version)
        add_version = new(new_version, previous_version)
        add_version.build_dirs
        add_version.build_files
        add_version.append_new_to_existing
      end

      def self.remove(version)
        remove_version = new(version, version)
        remove_version.rm_dirs
        remove_version.rm_files
      end

      def initialize(new_version, previous)
        @new_version = new_version
        @previous = previous
      end

      def append_new_to_existing
        puts "Need to append stuff here"
      end

      def rm_dirs
        # build new dirs
        dot_new = @new_version.split('x').join('.')
        %w[app/controllers/api spec/requests/api].each do |dir|
          path = dir.match('requests') ? "#{dir}/v#{dot_new}" : "#{dir}/v#{@new_version}"
          FileUtils.rm_rf(path)
        end
      end

      def rm_files
        # build new filess
        dot_new = @new_version.split('x').join('.')
        ["app/controllers/api/v#{@new_version}.rb", "config/routes/v#{@new_version}.rb", "public/doc/openapi-3-v#{dot_new}.json"].each_with_index do |file, index|
          FileUtils.rm(file)
        end
      end

      def build_dirs
        # build new dirs
        dot_new = @new_version.split('x').join('.')
        %w[app/controllers/api spec/requests/api].each do |dir|
          path = dir.match('requests') ? "#{dir}/v#{dot_new}" : "#{dir}/v#{@new_version}"
          raise StandardError.new("Path already exists") if check_existing?(path)
          FileUtils.mkdir(path)
        end
      end

      def build_files
        # build new files
        dot_prev = @previous.split('x').join('.')
        dot_new = @new_version.split('x').join('.')
        prev = ["app/controllers/api/v#{@previous}.rb", "config/routes/v#{@previous}.rb", "public/doc/openapi-3-v#{dot_prev}.json"]
        ["app/controllers/api/v#{@new_version}.rb", "config/routes/v#{@new_version}.rb", "public/doc/openapi-3-v#{dot_new}.json"].each_with_index do |file, index|
          raise StandardError.new("File already exists") if check_existing?(file)
          FileUtils.cp(prev[index], file)
        end
      end

      private

      def check_existing?(file_path)
        FileUtils.cd(file_path)
        true
      rescue Errno::ENOENT
        false
      end
    end
  end
end
