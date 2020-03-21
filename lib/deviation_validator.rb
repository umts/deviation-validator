# frozen_string_literal: true

require 'json'
require 'net/http'
require 'pathname'
require 'pony'

class DeviationValidator
  PVTA_API_URL = 'http://bustracker.pvta.com/InfoPoint/rest'

  def initialize
    root = Pathname(__dir__).join('..').expand_path
    stops_file = root.join('config', 'stops.txt')
    raise <<~MESSAGE unless stops_file.file?
      No config file found. Please see the stops.txt.example \
      file and create a stops.txt file to match.
    MESSAGE

    @date = Time.now.strftime('%Y-%m-%d')
    @stop_names = stops_file.read.lines.map(&:strip)
    @stop_ids = JSON.parse root.join('config', 'stops.json').read
    @daily_log_file = root.join('log', "#{@date}.txt")
  end

  # Intended to be run every day at 11:59 pm.
  def email_log
    mail_settings = { to: 'transit-it@admin.umass.edu',
                      from: 'transit-it@admin.umass.edu',
                      subject: "Deviation Daily Digest #{@date}" }
    mail_settings[:html_body] = @daily_log_file.read
    if ENV['DEVELOPMENT']
      # Use mailcatcher in development
      mail_settings[:via] = :smtp
      mail_settings[:via_options] = { address: 'localhost', port: 1025 }
    end
    Pony.mail mail_settings
  end

  def search
    @stop_names.each do |stop_name|
      stop_id = @stop_ids[stop_name]
      route_directions = query_departures(stop_id).first.fetch 'RouteDirections'
      route_directions.each do |route_dir|
        departures = route_dir.fetch 'Departures'
        departures.each do |departure|
          next if validate_departure(departure)

          report_deviation(stop_name, departure)
        end
      end
    end
  end

  private

  def query_departures(stop_id)
    departures_uri = URI("#{PVTA_API_URL}/stopdepartures/get/#{stop_id}")
    JSON.parse(Net::HTTP.get(departures_uri))
  end

  def report_deviation(stop_name, departure)
    deviation = departure.fetch('Dev')
    trip = departure.fetch('Trip')
    run_id = trip.fetch('RunId')
    headsign = trip.fetch('InternetServiceDesc')
    timestamp = Time.now.strftime '%l:%M %P'
    identifier = "#{timestamp}, #{stop_name}: "
    data = "Run #{run_id} (#{headsign}), deviation #{deviation}"
    @daily_log_file.open('a') { |file| file.puts identifier + data }
  end

  def validate_departure(departure)
    deviation = departure.fetch 'Dev'
    hours, minutes, _seconds = deviation.split(':').map(&:to_i)

    deviation[0] != '-' && hours < 1 && minutes < 10
  end
end
