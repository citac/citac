require 'thor'
require_relative '../../commons/logging'
require_relative '../../commons/model'
require_relative '../../commons/utils/serialization'
require_relative 'tasks/analyzation'
require_relative 'tasks/execution'
require_relative 'tasks/test'

module Citac
  module Agents
    module Puppet
      class CLI < Thor
        desc 'analyze [<dir>]', 'Analyzes the Puppet manifest in the given directory and stores the analyzation results in that directory.'
        def analyze(dir = '.')
          puts 'Generating dependency graph...'
          setup_workdir dir

          task = AnalyzationTask.new 'script'
          graph = task.execute :modulepath => 'modules'

          IO.write 'dependencies.graphml', graph.to_graphml, :encoding => 'UTF-8'
        end

        option :resource, :aliases => :r, :desc => 'The resource to execute'
        desc 'exec [-r <resource name>] [<dir>]', 'Executes the Puppet manifest in the given directory and stores the run results in that directory.'
        def exec(dir = '.')
          setup_workdir dir

          task = ExecutionTask.new 'script', options[:resource]
          task.execute :modulepath => 'modules', :output => :passthrough
        end

        option :passthrough, :aliases => :p, :desc => 'Enables output passthrough of test steps'
        desc 'test [<dir>]', 'Executes the Puppet test case in the given directory and stores the test results in that directory.'
        def test(dir = '.')
          setup_workdir dir

          test_case = Citac::Utils::Serialization.load_from_file 'test_case.yml'

          output = options[:passthrough] ? :passthrough : :redirect

          task = TestTask.new 'script', test_case, [] #TODO get exclusion patterns from somewhere
          test_case_result = task.execute :modulepath => 'modules', :output => output

          Citac::Utils::Serialization.write_to_file test_case_result, 'test_case_result.yml'
        end

        no_commands do
          def setup_workdir(dir)
            workdir = File.expand_path dir

            log_debug 'citac-agent-puppet', "Setting workdir to '#{workdir}'..."
            Dir.chdir workdir
          end
        end
      end
    end
  end
end