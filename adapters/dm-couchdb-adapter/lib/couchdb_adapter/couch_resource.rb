module DataMapper
  class Collection
    attr_accessor :total_rows
  end
end

module DataMapper
  module Couch
    module Resource

      def self.included(model)
        model.class_eval do
          include DataMapper::Resource

          property :attachments, DataMapper::Types::JsonObject, :field => '_attachments'
          property :id, String, :key => true, :field => '_id', :nullable => true
          property :rev, String, :field => '_rev'
          property :view, DataMapper::Types::JsonObject
          property :couchdb_type, DataMapper::Types::Discriminator

          include DataMapper::Couch::Attachments
          include DataMapper::Couch::Views

          def to_couchrest_hash
            values = {}
            properties.each do |property|
              next if property.name == 'view' || !(attribute_loaded?(property.name) && value = property.get!(self))
              values[property.field] = value
            end
            values
          end

        end
      end

    end # Resource
  end # Couch
end # DataMapper
