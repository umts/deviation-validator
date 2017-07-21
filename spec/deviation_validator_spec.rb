# frozen_string_literal: true

require 'spec_helper'

include DeviationValidator

describe DeviationValidator do
  describe 'query_departures' do
    let(:call) { query_departures 72 }
    it 'queries the expected URI' do
      stub_const('DeviationValidator::PVTA_API_URL', 'api_url')
      expected_uri = URI('api_url/stopdepartures/get/72')
      expect(Net::HTTP).to receive(:get)
        .with(expected_uri).and_return '{}'
      call
    end
    it 'parses it as JSON and returns the data' do
      data = { "apples" => 2, "bananas" => 17.5 }
      expect(Net::HTTP).to receive(:get)
        .and_return data.to_json
      expect(call).to eql data
    end
  end

  describe 'report_deviation' do
    it 'uses the expected attributes of a Trip object'
    it 'appends to a log file'
    it 'has the expected log entry format'
  end

  describe 'search' do
    it 'queries departures'
    it 'parses the expected data structure to scan for deviations'
    it 'reports negative deviations'
    it 'reports deviations of over ten minutes'
    it 'does not report deviations of under ten minutes'
  end
end
