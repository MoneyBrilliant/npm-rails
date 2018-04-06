# require "mkmf"
require 'fileutils'

module Npm
  module Rails
    module TaskHelpers

      # Copied from mkmkf, iwhich poolutes the global namespace and fucks with Rails.
      # Specifically, it adds a `configuration` method to every object, including nil.
      # This breaks things like `delegate :configuration, to: :something`. Argh.
      def self.find_executable(bin, path = nil)
          executable_file = proc do |name|
            begin
              stat = File.stat(name)
            rescue SystemCallError
            else
              next name if stat.file? and stat.executable?
            end
          end
          exts = config_string('EXECUTABLE_EXTS') {|s| s.split} || config_string('EXEEXT') {|s| [s]}
          if File.expand_path(bin) == bin
            return bin if executable_file.call(bin)
            if exts
              exts.each {|ext| executable_file.call(file = bin + ext) and return file}
            end
            return nil
          end
          if path ||= ENV['PATH']
            path = path.split(File::PATH_SEPARATOR)
          else
            path = %w[/usr/local/bin /usr/ucb /usr/bin /bin]
          end
          file = nil
          path.each do |dir|
            dir.sub!(/\A"(.*)"\z/m, '\1') if $mswin or $mingw
            return file if executable_file.call(file = File.join(dir, bin))
            if exts
              exts.each {|ext| executable_file.call(ext = file + ext) and return ext}
            end
          end
          nil
        end

      def self.find_browserify(npm_directory)
        browserify = find_executable("browserify") ||
          find_executable("#{ npm_directory }/.bin/browserify")

        if browserify.nil?
          raise Npm::Rails::BrowserifyNotFound, "Browserify not found! You can install Browserify using npm: npm install browserify -g"
        else
          browserify
        end
      end

      def self.create_file(path, file)
        unless File.directory?(path)
          FileUtils.mkdir_p(path)
        end

        file_path = path.join(file)
        FileUtils.touch(file_path)
      end
    end
  end
end
