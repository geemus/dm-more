require 'rubygems'
require 'lib/couchdb_adapter'

COUCHDB_LOCATION = "couchdb://localhost:5984/test_cdb_adapter"

DataMapper.setup(
  :couch,
  Addressable::URI.parse(COUCHDB_LOCATION)
)

#drop/recreate db
@adapter = DataMapper::Repository.adapters[:couch]
@adapter.send(:http_delete, "/#{@adapter.escaped_db_name}")
@adapter.send(:http_put, "/#{@adapter.escaped_db_name}")

class Person
  include DataMapper::Couch::Resource

  def self.default_repository_name
    :couch
  end

  property :name, String

  view_by :name
end

class Employee < Person
  property :title, String

  view_by :title
end

p Person.views
p Employee.views

Person.auto_migrate!
Employee.auto_migrate!

p bob = Person.create(:name => 'Bob')
# p Person.get(bob.id)
# p Person.all(:view => { :test => :options}).query.conditions.select {|condition| condition[1].name == :view}
p Person.first
p Person.all(:view => {:by_name => {}})
# p Employee.all(:view => {:by_title => {}})