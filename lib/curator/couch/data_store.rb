require 'ostruct'
require 'yaml'
require 'json'
require 'rest-client'

module Curator
  module Couch
    class DataStore
      def remove_all_keys
        all_docs = JSON.parse server['_all_docs'].get
        bulk_update = all_docs['rows'].map { |row| {:_id => row['id'], :_rev => row['value']['rev'], :_deleted => true} }

        server['_bulk_docs'].post({:docs => bulk_update}.to_json)
      end

      def reset!
        remove_all_keys
      end

      def save(options)
        key = options.delete(:key)

        document = options[:value]
        document.merge!(:_id => key) if key

        if key
          document.merge! :_id => key
          response = server[document[:_id]].put(document.to_json)
        else
          response = server.post(document.to_json)
        end

        JSON.parse(response)['id']
      end

      def delete(collection_name, key)
        # pending
      end

      def find_all(collection_name)
        # pending
      end

      def find_by_key(collection_name, key)
        doc = JSON.parse(server[key].get)
        doc.delete '_rev'

        {:key => doc.delete('_id'), :data => doc}
      end

      def default_db_name
        "#{Curator.config.database}_#{Curator.config.environment}"
      end

      def server
        @server ||= RestClient::Resource.new(_base_url, :headers => {:content_type => 'application/json', :accept => :json})
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
