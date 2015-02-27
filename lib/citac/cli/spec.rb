require 'thor'
require_relative 'ioc'
require_relative '../agent/analyzation'
require_relative '../agent/runner'
require_relative '../model'

module Citac
  module CLI
    class Spec < Thor
      desc 'list', 'Lists all stored configuration specifications.'
      def list
        ServiceLocator.specification_repository.each_spec do |spec_name|
          puts spec_name
        end
      end

      desc 'info <id>', 'Prints information about the stored configuration specification.'
      def info(spec_id)
        spec_id = clean_spec_id spec_id

        repo = ServiceLocator.specification_repository

        spec = repo.get spec_id
        run_count = repo.run_count spec

        puts "Id:\t#{spec.id}"
        puts "Name:\t#{spec.name}"
        puts "Type:\t#{spec.type}"
        puts "Runs:\t#{run_count}"

        env_mgr = ServiceLocator.environment_manager
        oss = env_mgr.operating_systems spec.type
        puts 'Operating systems:'
        spec.operating_systems.each do |os|
          next unless oss.include? os

          msg = "  - #{os}"
          msg << ' (analyzed)' if repo.has_dependency_graph? spec, os

          puts msg
        end
      end

      option :bulk, :type => :boolean, :aliases => :b
      option :quiet, :type => :boolean, :aliases => :q
      option :os, :aliases => :o
      option :action, :aliases => :a
      option :failed, :type => :boolean, :aliases => :f
      option :successful, :type => :boolean, :aliases => :s
      desc 'runs [-b] <id>', 'Prints all performed runs of the given configuration specification.'
      def runs(spec_id)
        raise 'Conflicting filter: failed and successful' if options[:successful] && options[:failed]

        spec_id = clean_spec_id spec_id

        repo = ServiceLocator.specification_repository

        if options[:bulk]
          lens = []
          repo.each_spec { |s| lens << s.length}
          len = lens.max
        end

        spec = repo.get spec_id

        puts "Action\t\tExit Code\tOS\tStart Time\t\t\tDuration" unless options[:bulk]
        puts "======\t\t=========\t==\t==========\t\t\t========" unless options[:bulk]

        runs = repo.runs(spec).to_a
        filter_runs! runs, options
        runs.sort_by! {|run| run.id}

        if runs.size > 0
          prefix = options[:bulk] ? "#{spec.to_s.ljust(len)}\t" : ''

          runs.each do |run|
            puts "#{prefix}#{run.action}\t\t#{run.exit_code}\t\t#{run.operating_system}\t#{run.start_time}\t#{run.duration.round(2).to_s.rjust(6)} s"
          end
        elsif !options[:quiet]
          if options[:bulk]
            puts "#{spec.to_s.ljust(len)}\tNo runs found."
          else
            puts "No runs of #{spec} found."
          end
        end
      end

      option :os, :aliases => :o
      option :action, :aliases => :a
      option :failed, :type => :boolean, :aliases => :f
      option :successful, :type => :boolean, :aliases => :s
      desc 'clearruns <id>', 'Clears all saved runs of the given configuration specification.'
      def clearruns(spec_id)
        spec_id = clean_spec_id spec_id

        repo = ServiceLocator.specification_repository
        spec = repo.get spec_id
        run_count = repo.run_count spec

        puts "Deleting matching runs of #{spec}..."
        count = 0

        runs = repo.runs(spec).to_a
        filter_runs! runs, options
        runs.each do |run|
          repo.delete_run run
          count += 1
        end

        puts "Deleted #{count} out of #{run_count} runs."
      end

      option :force, :type => :boolean, :aliases => :f
      desc 'analyze [--force|-f] <spec> [<os>]', 'Generates the dependency graph for the given configuration specification.'
      def analyze(spec_name, os = nil)
        spec_name = clean_spec_id spec_name

        os = Citac::Model::OperatingSystem.parse os if os

        repo = ServiceLocator.specification_repository
        env_mgr = ServiceLocator.environment_manager

        spec = repo.get spec_name

        oss = env_mgr.operating_systems(spec.type).to_a
        oss.select! {|o| spec.operating_systems.include? o} unless spec.operating_systems.empty?
        oss.select! {|o| o.matches? os} if os

        if oss.any?
          analyzer = Citac::Agent::Analyzer.new repo, env_mgr
          oss.each do |os|
            analyzer.run spec, os, :force => options[:force]
          end
        else
          puts "No compatible operating system found for #{spec}."
        end
      end

      option :trace, :aliases => :t, :type => :boolean, :desc => 'enables system call tracing'
      desc 'exec <spec> <os>', 'Runs the given configuration specification on the specified operating system.'
      def exec(spec_name, os = nil)
        spec_name = clean_spec_id spec_name
        os = Citac::Model::OperatingSystem.parse os if os

        repo = ServiceLocator.specification_repository
        env_mgr = ServiceLocator.environment_manager

        spec = repo.get spec_name

        oss = env_mgr.operating_systems(spec.type).to_a
        oss.select! {|o| spec.operating_systems.include? o} unless spec.operating_systems.empty?
        oss.select! {|o| o.matches? os} if os

        raise "No suitable environment found for executing #{spec} on '#{os}'" if oss.empty?

        os = oss.first

        puts "Executing #{spec} on #{os}..."

        runner = Citac::Agent::Runner.new repo, env_mgr
        runner.trace = options[:trace]
        runner.run spec, os
      end

      option :type, :aliases => :t, :default => 'dot'
      desc 'dg [-t <type>] <spec> [<file name>]', 'Extracts the stored dependency graph of the configuration specification.'
      def dg(spec_name, file_name = nil)
        spec_name = clean_spec_id spec_name
        file_name ||= "#{spec_name.gsub('/', '_').gsub("\\", '_')}.#{options[:type]}"

        repo = ServiceLocator.specification_repository
        spec = repo.get spec_name

        oss = spec.operating_systems
        if oss.empty?
          env_mgr = ServiceLocator.environment_manager
          oss = env_mgr.operating_systems spec.type
        end

        oss.each do |os|
          next unless repo.has_dependency_graph? spec, os

          puts "Getting #{options[:type]} graph for #{spec} on #{os} and saving to #{file_name}..."
          graph = repo.dependency_graph spec, os

          method_name = "to_#{options[:type]}"
          output = graph.send method_name, {:tred => true}

          IO.write file_name, output
          return
        end

        raise "No stored dependency graph found for #{spec}."
      end

      no_commands do
        def clean_spec_id(spec_id)
          spec_id.gsub /\.spec\/?/i, ''
        end

        def filter_runs!(runs, options)
          runs.select! {|run| run.exit_code == 0} if options[:successful]
          runs.reject! {|run| run.exit_code == 0} if options[:failed]
          runs.select! {|run| run.action == options[:action]} if options[:action]

          if options[:os]
            os = Citac::Model::OperatingSystem.parse options[:os]
            runs.select!{|run| run.operating_system.matches? os}
          end
        end
      end
    end
  end
end