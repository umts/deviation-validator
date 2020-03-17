# frozen_string_literal: true

require_relative 'deviation_validator'
include DeviationValidator

namespace :deviations do
  desc "Email today's log file"
  task :email_log do
    DeviationValidator.email_log
  end

  desc 'look for and log abnormal deviations'
  task :search do
    DeviationValidator.search
  end
end
