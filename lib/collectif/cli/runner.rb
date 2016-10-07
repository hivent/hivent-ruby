# frozen_string_literal: true
require 'optparse'
require "active_support"
require "active_support/core_ext"

require_relative "./start_option_parser"
require_relative "./consumer"

module Collectif

  module CLI

    class Runner

      OPTION_PARSERS = {
        start: StartOptionParser
      }.freeze

      def initialize(argv)
        @argv = argv
        @command = @argv.shift.to_s.to_sym
      end

      def run
        if parser = OPTION_PARSERS[@command]
          send(@command, parser.new(@command, @argv).parse)
        else
          puts help
        end
      end

      private

      def start(options)
        Consumer.run!(options)
      end

      def help
        <<-EOS.strip_heredoc
          Available COMMANDs are:
             start  :  starts one or multiple the consumer
          See 'collectif_receiver COMMAND --help' for more information on a specific command.
        EOS
      end

    end

  end

end
