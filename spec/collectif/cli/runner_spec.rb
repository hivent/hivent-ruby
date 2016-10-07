# frozen_string_literal: true
require "spec_helper"

describe Collectif::CLI::Runner do

  describe "#run" do

    subject { runner.run }

    let(:runner) { described_class.new(([command] + args).compact) }
    let(:args) { [] }
    let(:require_file) { File.expand_path("../../../fixtures/cli/bootstrap_consumers.rb", __FILE__) }

    context "with no command" do

      let(:command) { nil }

      it "prints help for available commands" do
        expect(with_captured_stdout { subject }).to include("Available COMMANDs are")
      end

    end

    context "with unknown command" do

      let(:command) { "unknown" }

      it "prints help for available commands" do
        expect(with_captured_stdout { subject }).to include("Available COMMANDs are")
      end

    end

    context "with --help option" do

      let(:args) { ["--help"] }

      ["start"].each do |cmd|

        context "with #{cmd} command" do

          let(:command) { cmd }

          it "prints help for #{cmd} command options" do
            output = with_captured_stdout do
              begin
                subject
              rescue SystemExit
                # do nothing
              end
            end
            expect(output).to include("Usage: collectif_receiver #{cmd} [options]")
          end

        end

      end

    end

    context "with start command and all required arguments" do

      let(:command) { "start" }
      let(:args) { ["--require", require_file] }

      it "starts the consumer" do
        expect(Collectif::CLI::Consumer).to receive(:run!).once
        subject
      end

    end

  end

end
