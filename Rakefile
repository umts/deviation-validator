# frozen_string_literal: true

require_relative 'deviation_validator'
include DeviationValidator

namespace :deviations do
  task :email_digest do
    DeviationValidator.email_log!
  end

  task :search do
    DeviationValidator.search
  end
end
