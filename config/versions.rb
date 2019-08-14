# frozen_string_literal: true

require 'terrapin'

SNAP_VERSION = ENV['SNAP_VERSION'] ||= '0.0.0'
API_VERSION = case File.exist? 'build_version'
              when true
                File.read('build_version').chomp
              when false
                begin
                  Terrapin::CommandLine.new(
                    'git',
                    'describe --always',
                    expected_outcodes: [0, 1]
                  ).run&.chomp!.freeze
                rescue Terrapin::CommandLineError
                  # git not installed
                  '0.0.0'
                end
              else
                '0.0.0'
              end
