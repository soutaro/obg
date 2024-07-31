# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"

Minitest::TestTask.create

task default: :test

namespace :rbs do
  task :generate do
    sh "rbs-inline --opt-out --output lib"
  end

  task :watch do
    sh "fswatch -0 lib | xargs -n1 -0 rbs-inline --opt-out --output lib"
  rescue Interrupt
    # nop
  end
end
