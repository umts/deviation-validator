# frozen_string_literal: true

require 'json'
require 'net/http'
require 'pry-byebug'

module DeviationValidator
  raise <<~MESSAGE unless File.file? 'stops.txt'
    No config file found. Please see the stops.txt.example \
    file and create a stops.txt file to match.
  MESSAGE

  STOP_NAMES = File.read('stops.txt').lines.map(&:strip)

  STOP_IDS = JSON.parse File.read('stops.json')

  PVTA_API_URL = 'http://bustracker.pvta.com/InfoPoint/rest'

  DAILY_LOG_FILE = "log/#{Time.now.strftime('%Y-%m-%d')}.txt"

  def query_departures(stop_id)
    departures_uri = URI([PVTA_API_URL, 'stopdepartures', 'get', stop_id].join('/'))
    JSON.parse(Net::HTTP.get(departures_uri))
  end

  def report_deviation(departure)
    trip = departure.fetch('Trip')
    run_id = trip.fetch('RunId')
    headsign = trip.fetch('InternetServiceDesc')
    timestamp = Time.now.strftime '%l:%M %P'
    File.open DAILY_LOG_FILE, 'a' do |file|
      file.puts "#{timestamp}, #{name}: Run #{run_id} (#{headsign}), deviation #{deviation}"
    end
  end

  def search
    STOP_NAMES.each do |name|
      stop_id = STOP_IDS[name]
      departures = query_departures(stop_id)
      route_directions = departures.first.fetch 'RouteDirections'
      route_directions.each do |route_dir|
        departures = route_dir.fetch 'Departures'
        departures.each do |departure|
          # Example: "00:05:30", meaning that the bus is 5 1/2 minutes behind
          deviation = departure.fetch 'Dev'
          if deviation[0] == '-'
            # THE BUS IS EARLY!
            report_deviation(departure)
          else
            hours, minutes, _seconds = deviation.split(':').map(&:to_i)
            if hours.positive? || minutes > 10
              # THE BUS IS LATE!
              report_deviation(departure)
            end
          end
        end
      end
    end
  end
end
