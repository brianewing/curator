require 'ostruct'
require 'yaml'

module Curator
  module Couch
    class DataStore
      def remove_all_keys
        # pending
      end

      def reset!
        # pending
      end

      def save(options)
        # pending
      end

      def delete(collection_name, key)
        # pending
      end

      def find_all(collection_name)
        # pending
      end

      def find_by_key(collection_name, key)
        #pending
      end

      def default_db_name
        "#{Curator.config.database}_#{Curator.config.environment}"
      end

      def _config
        @yml_config ||= YAML.load(File.read(Curator.config.couch_config_file))[Curator.config.environment]
      end

      def _base_url
        return @base_url if @base_url

        if _config[:url]
          @base_url = _config[:url].sub(/(\/)$/, '') # no trailing slash
        else
          scheme = _config[:ssl] ? 'https' : 'http'
          auth = _config[:username] ? "#{_config[:username]}:#{_config[:password]}@" : ''
          host = _config[:host]
          port = _config[:port] || 5984
          database = _config[:database] || default_db_name

          @base_url = "#{scheme}://#{auth}#{host}:#{port}/#{database}"
        end
      end
    end
  end
end
