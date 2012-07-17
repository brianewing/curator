require 'active_support/inflector'
require 'active_support/core_ext/object/instance_variables'
require 'active_support/core_ext/hash/indifferent_access'
require 'json'

module Curator
  module Repository
    extend ActiveSupport::Concern

    module ClassMethods
      def collection(explicit_collection_name)
        @collection_name = explicit_collection_name
      end

      def collection_name
        @collection_name ||= default_collection_name
      end

      def default_collection_name
        ActiveSupport::Inflector.tableize(klass)
      end

      def data_store
        @data_store ||= Curator.data_store
      end

      def data_store=(store)
        @data_store = store
      end

      def delete(object)
        data_store.delete(collection_name, object.id)
        nil
      end

      def find_by_created_at(start_time, end_time)
        _find_by_attribute(:created_at, _format_time_for_index(start_time).._format_time_for_index(end_time))
      end

      def find_by_updated_at(start_time, end_time)
        _find_by_attribute(:updated_at, _format_time_for_index(start_time).._format_time_for_index(end_time))
      end

      def find_by_version(version)
        _find_by_attribute(:version, version)
      end

      def find_by_id(id)
        if hash = data_store.find_by_key(collection_name, id)
          _deserialize(hash[:key], hash[:data])
        end
      end

      def indexed_fields(*fields)
        @indexed_fields = fields

        @indexed_fields.each do |field_name|
          _build_finder_methods(field_name)
        end
      end

      def klass
        name.to_s.gsub("Repository", "").constantize
      end

      def migrator
        @migrator ||= Curator::Migrator.new(collection_name)
      end

      def save(object)
        object.touch
        save_without_timestamps(object)
      end

      def save_without_timestamps(object)
        hash = {
          :collection_name => collection_name,
          :value => _serialize(object),
          :index => _indexes(object)
        }

        if object.id
          hash[:key] = object.id
          data_store.save(hash)
        else
          object.instance_variable_set("@id", data_store.save(hash))
        end

        object
      end

      def serialize(object)
        HashWithIndifferentAccess.new(object.instance_values)
      end

      def _build_finder_methods(attribute)
        eigenclass = class << self; self; end
        eigenclass.class_eval do
          define_method("find_by_#{attribute}") do |value|
            _find_by_attribute(attribute, value)
          end
          define_method("find_first_by_#{attribute}") do |value|
            _find_by_attribute(attribute, value).first
          end
        end
      end

      def _find_by_attribute(attribute, value)
        if results = data_store.find_by_attribute(collection_name, attribute, value)
          results.map do |hash|
            _deserialize(hash[:key], hash[:data])
          end
        end
      end

      def deserialize(attributes)
        klass.new(attributes)
      end

      def _deserialize(id, data)
        attributes = data.with_indifferent_access
        migrated_attributes = migrator.migrate(attributes)
        migrated_attributes[:id] = id
        deserialize(migrated_attributes)
      end

      def _format_time_for_index(time)
        time.to_json.gsub('"', '')
      end

      def _indexed_fields
        @indexed_fields || []
      end

      def _indexes(object)
        index_values = _indexed_fields.map { |field| [field, serialize(object)[field.to_sym]] }
        index_values += [
          [:created_at, _format_time_for_index(object.send(:created_at))],
          [:updated_at, _format_time_for_index(object.send(:updated_at))],
          [:version, object.version]
        ]
        r = Hash[index_values]
        puts "_indexes: #{r.inspect}"
        r
      end

      def _serialize(object)
        serialize(object).reject { |key, val| val.nil? }.merge(:version => object.version)
      end

      def _update_timestamps(object)
        object.updated_at = Time.now.utc
        object.created_at ||= object.updated_at
      end
    end
  end
end
