# frozen_string_literal: true
require "spec_helper"

describe Hivent::CLI::StartOptionParser do

  let(:parser) { described_class.new(:start, args) }
  let(:args) { [] }
  let(:require_file) { File.expand_path("../../../fixtures/cli/bootstrap_consumers.rb", __FILE__) }

  describe "#parse" do

    subject { silence { parser.parse } }

    context "when --require option is omitted" do

      it "terminates" do
        expect { subject }.to exit_with_code(1)
      end

    end

    context "when --require is given" do

      let(:args) { ["--require", require_file] }

      it "does not terminate" do
        expect { subject }.not_to exit_with_code(1)
      end

      it "sets options for require" do
        expect(subject[:require]).to eq(args.last)
      end

      context "but does not exist" do

        let(:args) { ["--require", "/does/not/exist.rb"] }

        it "terminates" do
          expect { subject }.to exit_with_code(1)
        end

      end

    end

  end

end
