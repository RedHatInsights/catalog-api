require 'fileutils'
module Api
  module Tools
    class Versioning
      def self.build_new(version)
        _self = new(version)
        _self.build_dirs
        _self.build_files
        _self.append_new_to_existing
      end

      def initialize(version)
        @version = version
        @last_known_minor
        @last_known_major
      end

      def append_new_to_existing
        puts "Appending stuff"
      end

      def build_dirs
        # build new dirs
        %w[app/controllers/api specs/requests/api].each do |dir|
          path = "#{dir}/v#{@version}"
          raise StandardError.new("Path already exists") if check_existing?(path)
          FileUtils.mkdir(path)
        end
      end

      def build_files
        # build new filess
        ["config/routes/v#{@version}", "public/doc/openapi-3v#{version}.json"].each do |file|
          raise StandardError.new("File already exists") if check_existing?(file)
          FileUtils.cp(file)
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
