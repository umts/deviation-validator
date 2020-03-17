# frozen_string_literal: true

require_relative '../deviation_validator'

RSpec.describe DeviationValidator do
  let(:dv) { DeviationValidator.new }

  describe 'email_log' do
    before :each do
      stub_const('ENV', 'DEVELOPMENT' => development)
      dv.instance_variable_set :@daily_log_file, :log_file
      expect(File).to receive(:read).with(:log_file).and_return :file_contents
    end

    let(:call) { dv.email_log }
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
    let(:call) { dv.send(:query_departures, 72) }
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
    before(:each) { dv.instance_variable_set :@daily_log_file, :log_file }
    def call(*args)
      dv.send(:report_deviation, *args)
    end

    it 'appends to a log file with the correct entry format' do
      expect(departure).to receive(:fetch).with('Trip').and_return trip
      expect(departure).to receive(:fetch).with('Dev').and_return 'DEVIATION'
      expect(trip).to receive(:fetch).with('RunId')
                                     .and_return 'RUN'
      expect(trip).to receive(:fetch).with('InternetServiceDesc')
                                     .and_return 'HEADSIGN'
      expect(File).to receive(:open).with(:log_file, 'a').and_yield file
      timestamp = '12:00 pm, STOP NAME: Run RUN (HEADSIGN), deviation DEVIATION'
      expect(file).to receive(:puts).with timestamp
      Timecop.freeze Time.new(2017, 7, 31, 12) do
        call 'STOP NAME', departure
      end
    end
  end

  # I didn't feel the need to write a `let` statement aliasing `result`
  # for `search`.
  describe 'search' do
    let(:deviation) { '00:00:00' }
    let :departures do
      [
        { 'RouteDirections' => [
          {
            'Departures' => [
              { 'Dev' => deviation }
            ]
          }
        ] }
      ]
    end
    let(:call) { dv.search }
    let :setup_expectation do
      expect(dv).to receive(:query_departures)
        .with(:stop_id).and_return departures
    end

    before :each do
      dv.instance_variable_set :@stop_names, ['Stop Name']
      dv.instance_variable_set :@stop_ids, 'Stop Name' => :stop_id
    end

    # If this test fails, it's because the data structure the method is using
    # isn't what's created in this test, so `fetch` calls are failing.
    it 'parses the expected query data structure to scan for deviations' do
      setup_expectation
      expect { call }.not_to raise_exception
    end

    context 'deviations' do
      before(:each) { setup_expectation }
      context 'with a negative deviation' do
        let(:deviation) { '-00:00:30' }
        it 'reports' do
          expect(dv).to receive :report_deviation
          call
        end
      end
      context 'with a deviation of 10 minutes or more' do
        let(:deviation) { '00:10:15' }
        it 'reports' do
          expect(dv).to receive :report_deviation
          call
        end
      end
      context 'with a deviation of under 10 minutes' do
        let(:deviation) { '00:09:45' }
        it 'does not report' do
          expect(dv).not_to receive :report_deviation
          call
        end
      end
    end
  end
end
