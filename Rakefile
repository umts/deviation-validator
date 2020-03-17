# frozen_string_literal: true

require_relative 'deviation_validator'

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
