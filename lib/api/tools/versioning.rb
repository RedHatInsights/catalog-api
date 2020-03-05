require 'fileutils'
module Api
  module Tools
    class Versioning
      def self.build_new(new_version, previous_version)
        Add.new(new_version, previous_version).apply
      end

      def self.remove(version, previous)
        Remove.new(version, previous).apply
      end

      def initialize(version, previous)
        @version = version
        @previous = previous
        @dot_prev = @previous.split('x').join('.')
        @dot_new = @version.split('x').join('.')
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
