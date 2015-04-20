require 'thor'
require_relative '../ioc'

module Citac
  module Main
    module CLI
      class Envs < Thor
        def initialize(*args)
          super
          @env_mgr = ServiceLocator.environment_manager
        end

        desc 'setup', 'Creates all environments.'
        def setup
          @env_mgr.setup
        end

        desc 'list', 'Lists all available environments.'
        def list
          @env_mgr.environments.each do |env|
            puts env
          end
        end

        desc 'update [<id>]', 'Updates package caches etc. on a specific or all environments.'
        def update(id = nil)
          envs = id ? [@env_mgr.get(id)] : @env_mgr.environments.to_a

          envs.each do |env|
            puts "Updating #{env}..."
            @env_mgr.update env, :output => :passthrough
          end
        end
      end
    end
  end
end