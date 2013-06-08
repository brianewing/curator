require 'spec_helper'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/date/calculations'
require 'curator/couch/data_store'
require 'curator/shared_data_store_specs'

module Curator::Couch
  describe Curator::Couch::DataStore do
    include_examples "data_store", DataStore

    let(:data_store) { DataStore.new }

    with_config do
      Curator.configure(:couch) do |config|
        config.environment = 'test'
      end
    end
  end
end
