# frozen_string_literal: true
module Hivent

  module CLI

    class StartOptionParser

      def initialize(command, argv)
        @command = command
        @argv = argv
      end

      def parse
        return @options if @options
        @options = {}

        parser = OptionParser.new do |o|
          o.banner = "Usage: hivent #{@command} [options]"

          o.on('-r', '--require PATH', 'File to require to bootstrap consumers') do |arg|
            @options[:require] = arg
          end
        end

        parser.parse(@argv)

        validate_options

        @options
      end

      def validate_options
        if @options[:require].nil? || !File.exist?(@options[:require])
          puts <<-EOS.strip_heredoc
            =========================================================
              Please point hivent to a Ruby file
              to load your consumers with -r FILE.
            =========================================================
          EOS

          exit(1)
        end
      end

    end

  end

end
