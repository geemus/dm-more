require 'pathname'
require Pathname(__FILE__).dirname.parent.expand_path + 'lib/couchdb_adapter'

COUCHDB_LOCATION = "couchdb://localhost:5984/test_cdb_adapter"

DataMapper.setup(
  :couch,
  Addressable::URI.parse(COUCHDB_LOCATION)
)

#drop/recreate db

@adapter = DataMapper::Repository.adapters[:couch]
begin
  @adapter.send(:http_delete, "/#{@adapter.escaped_db_name}")
  @adapter.send(:http_put, "/#{@adapter.escaped_db_name}")
  COUCHDB_AVAILABLE = true
rescue Errno::ECONNREFUSED
  warn "CouchDB could not be contacted at #{COUCHDB_LOCATION}, skipping online dm-couchdb-adapter specs"
  COUCHDB_AVAILABLE = false
end

begin
  gem 'dm-serializer'
  require 'dm-serializer'
  DMSERIAL_AVAILABLE = true
rescue LoadError
  DMSERIAL_AVAILABLE = false
end

if COUCHDB_AVAILABLE
  class User
    include DataMapper::Couch::Resource
    def self.default_repository_name
      :couch
    end

    # regular properties
    property :name, String
    property :age, Integer
    property :wealth, Float
    property :created_at, DateTime
    property :created_on, Date
    property :location, JsonObject

    # creates methods for accessing stored/indexed views in the CouchDB database
    view(:by_name) {{ "map" => "function(doc) { if (#{couchdb_types_condition}) { emit(doc.name, doc); } }" }}
    view(:by_age)  {{ "map" => "function(doc) { if (#{couchdb_types_condition}) { emit(doc.age, doc); } }" }}
    view(:count)   {{ "map" => "function(doc) { if (#{couchdb_types_condition}) { emit(null, 1); } }",
                      "reduce" => "function(keys, values) { return sum(values); }" }}

    belongs_to :company

    before :create do
      self.created_at = DateTime.now
      self.created_on = Date.today
    end
  end

  class Company
    include DataMapper::Couch::Resource
    def self.default_repository_name
      :couch
    end

    # This class happens to have similar properties
    property :name, String
    property :age, Integer

    has n, :users
  end

  class Person
    include DataMapper::Couch::Resource
    def self.default_repository_name
      :couch
    end

    property :name, String
  end

  class Employee < Person
    property :rank, String
  end

  class Broken
    include DataMapper::Couch::Resource
    def self.default_repository_name
      :couch
    end

    property :couchdb_type, Discriminator
    property :name, String
  end

  class Viewable
    include DataMapper::Couch::Resource
    def self.default_repository_name
      :couch
    end

    property :name, String
    property :open, Boolean
  end
end