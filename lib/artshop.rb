require "bundler/setup"
require "dry/cli"
require "os"
require_relative "artshop/shipper"
require_relative "artshop/version"

module ArtShop
  class Error < StandardError; end

  module CLI
    module Commands
      extend Dry::CLI::Registry

      class Version < Dry::CLI::Command
        desc "Print version"

        def call(*)
          puts "artshop #{ArtShop::VERSION}"
          begin
            puts OS.report
            puts "ruby_bin: #{OS.ruby_bin}"
          rescue
            nil
          end
        end
      end

      class Ship < Dry::CLI::Command
        desc "Run shipments script"

        option :test, type: :boolean, default: false, desc: "Run in test mode"

        def call(**options)
          ArtShop::Scripts.ship(test: options.fetch(:test))
        end
      end

      register "version", Version, aliases: ["v", "-v", "--version"]
      register "ship", Ship
    end
  end
end
