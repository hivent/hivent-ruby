# frozen_string_literal: true
module Collectif

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
          o.banner = "Usage: collectif_receiver #{@command} [options]"

          o.on('-r', '--require PATH', 'File to require to bootstrap consumers') do |arg|
            @options[:require] = arg
          end

          o.on('-p', '--pid-dir DIR', 'Location of worker pid files') do |arg|
            @options[:pid_dir] = arg
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
              Please point collectif_receiver to a Ruby file
              to load your consumers with -r FILE.
            =========================================================
          EOS

          exit(1)
        end
      end

    end

  end

end
