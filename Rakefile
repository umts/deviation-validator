# frozen_string_literal: true

require 'pathname'
$LOAD_PATH.unshift Pathname(__dir__).join('lib').expand_path

require 'deviation_validator'

namespace :deviations do
  desc "Email today's log file"
  task :email_log do
    dv = DeviationValidator.new
    dv.email_log
  end

  desc 'look for and log abnormal deviations'
  task :search do
    dv = DeviationValidator.new
    dv.search
  end
end
