# frozen_string_literal: true

env :PATH, ENV['PATH']

job_type :rake, 'cd :path && bundle exec rake :task'

# Every minute after 5am until 3am, check for deviations.
# Raw cron asterisk order: minute, hour, day of month, month, day of week
every '* 0-2,5-23 * * *' do
  rake 'deviations:search'
end

every :day, at: '11:59pm' do
  rake 'deviations:email_log'
end
