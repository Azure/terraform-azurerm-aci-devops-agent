# Official gems.
require 'colorize'
require 'rspec/core/rake_task'

# Git repo gems.
require 'bundler/setup'
require 'terramodtest'

namespace :presteps do
  task :ensure do
    puts "Using go mod to install required go packages.\n"
    success = system ("cd test && go mod download")
    if not success 
      raise "ERROR: go mod download failed!\n".red
    end
  end
end

namespace :static do
  task :style do
    style_tf
  end
  task :lint do
    lint_tf
  end
  task :format do
    format_tf
  end
end

namespace :integration do
  task :test do
    success = system ("cd test && go test -v ./ -timeout 20m")
    if not success 
      raise "ERROR: Go test failed!\n".red
    end
  end
end

task :prereqs => [ 'presteps:ensure' ]

task :validate => [ 'static:style', 'static:lint' ]

task :format => [ 'static:format' ]

task :build => [ 'prereqs', 'validate' ]

task :unit => []

task :e2e => [ 'prereqs', 'integration:test' ]

task :default => [ 'build' ]

task :full => [ 'build', 'unit', 'e2e' ]