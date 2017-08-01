# frozen_string_literal: true

require 'spec_helper'

include DeviationValidator

describe DeviationValidator do
  describe 'email_log' do
    before :each do
      stub_const('ENV', 'DEVELOPMENT' => development)
      stub_const('DeviationValidator::DAILY_LOG_FILE', :log_file)
      expect(File).to receive(:read).with(:log_file).and_return :file_contents
    end
    let(:call) { email_log }
    let(:development) { false }
    let :set_mailer_expectation do
      expect(Pony).to receive(:mail).with hash_including @mail_params
    end
    let(:transit_it) { 'transit-it@admin.umass.edu' }
    it 'mails the contents of the log file' do
      @mail_params = { html_body: :file_contents }
      set_mailer_expectation
      call
    end
    it 'mails to transit-it' do
      @mail_params = { to: transit_it }
      set_mailer_expectation
      call
    end
    it 'mails from transit-it' do
      @mail_params = { from: transit_it }
      set_mailer_expectation
      call
    end
    context 'in development' do
      let(:development) { true }
      it 'mails via smtp at localhost:1025' do
        @mail_params = { via: :smtp,
                         via_options: { address: 'localhost', port: 1025 } }
        set_mailer_expectation
        call
      end
    end
  end

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
      data = { 'apples' => 2, 'bananas' => 17.5 }
      expect(Net::HTTP).to receive(:get)
        .and_return data.to_json
      expect(call).to eql data
    end
  end

  describe 'report_deviation' do
    let(:departure) { double }
    let(:trip) { double }
    let(:file) { double }
    it 'appends to a log file with the correct entry format' do
      expect(departure).to receive(:fetch).with('Trip').and_return trip
      expect(departure).to receive(:fetch).with('Dev').and_return 'DEVIATION'
      expect(trip).to receive(:fetch).with('RunId')
        .and_return 'RUN'
      expect(trip).to receive(:fetch).with('InternetServiceDesc')
        .and_return 'HEADSIGN'
      stub_const 'DeviationValidator::DAILY_LOG_FILE', :log_file
      expect(File).to receive(:open).with(:log_file, 'a').and_yield file
      timestamp = '12:00 pm, STOP NAME: Run RUN (HEADSIGN), deviation DEVIATION'
      expect(file).to receive(:puts).with timestamp
      Timecop.freeze(Time.new 2017, 7, 31, 12) { report_deviation('STOP NAME', departure) }
    end
  end

  describe 'search' do
    it 'queries departures'
    it 'parses the expected data structure to scan for deviations'
    it 'reports negative deviations'
    it 'reports deviations of over ten minutes'
    it 'does not report deviations of under ten minutes'
  end
end
