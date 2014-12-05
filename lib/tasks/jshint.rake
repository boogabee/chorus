JSHINT_RAKE_TASK_COMPATIBILITY_MESSAGE = <<EOT
This rake task is included only for compatibility with old git pre-commit hooks that might be floating around.
Please run script/lint_all.sh or script/lint_changed.sh directly instead.
EOT

task :jshint do
  puts JSHINT_RAKE_TASK_COMPATIBILITY_MESSAGE
  sh("script/lint_all.sh")
end
task :lint => :jshint
task :hint => :jshint
task :jslint => :jshint

namespace :jshint do
  task :all do
    puts JSHINT_RAKE_TASK_COMPATIBILITY_MESSAGE
    sh("script/lint_all.sh")
  end

  task :changed do
    puts JSHINT_RAKE_TASK_COMPATIBILITY_MESSAGE
    sh("script/lint_changed.sh")
  end
end
