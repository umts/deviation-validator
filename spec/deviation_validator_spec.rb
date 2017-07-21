# frozen_string_literal: true

require 'spec_helper'

describe DeviationValidator do
  describe 'query_departures' do
    it 'queries the expected URI'
    it 'parses it as JSON and returns the data'
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
