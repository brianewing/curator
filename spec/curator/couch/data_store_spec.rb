require 'spec_helper'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/date/calculations'
require 'curator/couch/data_store'
require 'curator/shared_data_store_specs'

module Curator::Couch
  describe Curator::Couch::DataStore do
    include_examples "data_store", DataStore

    let(:data_store) { DataStore.new }

    def with_stubbed_yml_config(yml)
      data_store.instance_variable_set(:@yml_config, nil)
      File.stub(:read).and_return(yml); yield; File.unstub(:read)
    end

    def base_url
      data_store.instance_variable_set(:@base_url, nil)
      data_store._base_url
    end

    with_config do
      Curator.configure(:couch) do |config|
        config.environment = 'test'
        config.database = 'curator'
        config.couch_config_file = File.expand_path(File.dirname(__FILE__) + "/../../../config/couch.yml")
      end
    end

    it "should correctly parse url from config" do
      with_stubbed_yml_config(<<-YML) { base_url.should == "http://example:1234/curator_test" }
        test:
          :host: example
          :port: 1234
      YML

      with_stubbed_yml_config(<<-YML) { base_url.should == "https://foo:bar@example:5984/curator_test" }
        test:
          :host: example
          :ssl: true
          :username: foo
          :password: bar
      YML

      with_stubbed_yml_config(<<-YML) { base_url.should == "http://example:5984/specific_database" }
        test:
          :host: example
          :database: specific_database
      YML

      with_stubbed_yml_config(<<-YML) { base_url.should == "http://exactly-as-given-without-trailing-slash/db" }
        test:
          :url: http://exactly-as-given-without-trailing-slash/db/
      YML
    end
  end
end
