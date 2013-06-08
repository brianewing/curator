module Curator::Couch
  class Configuration
    include Curator::Configuration

    attr_accessor :database, :couch_config_file

    def data_store
      Curator::Couch::DataStore.new
    end
  end
end
