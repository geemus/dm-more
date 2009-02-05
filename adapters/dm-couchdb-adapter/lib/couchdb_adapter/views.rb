module DataMapper
  module Couch
    module Views

      def self.included(model)
        model.extend(ClassMethods)
        model.instance_variable_set(:@views, model.default_views)

        model.class_eval do
          def self.inherited(target)
            super
            target.instance_variable_set(:@views, target.default_views)
            # add_scope_for_discriminator since the after call doesn't seem to be happening
            target.descendants << target
            target.default_scope.update(:couchdb_type => target.descendants)
            propagate_descendants(target)
          end
        end
      end

      module ClassMethods

        def default_views
          {
            'views' => {
              'all' => Proc.new {
                {
                  'map' => <<-JAVASCRIPT
function(doc) {
  if (#{couchdb_types_condition}) {
    emit(doc['_id'], doc);
  }
}
JAVASCRIPT
                }
              }
            }
          }
        end

        def couchdb_types
          [self] | self.descendants
        end

        def couchdb_types_condition
          couchdb_types.collect {|type| "doc['couchdb_type'] == '#{type}'"}.join(' || ')
        end

        def view_by *keys
          opts = keys.pop if keys.last.is_a?(Hash)
          opts ||= {}
          ducktype = opts.delete(:ducktype)
          unless ducktype || opts[:map]
            opts[:guards] ||= []
          end

          method_name = "by_#{keys.join('_and_')}"

          if opts[:map]
            view = {}
            view['map'] = opts.delete(:map)
            if opts[:reduce]
              view['reduce'] = opts.delete(:reduce)
              opts[:reduce] = false
            end
            @views['views'][method_name] = Proc.new { view }
          else
            view_keys = keys.collect { |key| "doc['#{key}']" }
            key_emit = view_keys.length == 1 ? "#{view_keys.first}" : "[#{view_keys.join(', ')}]"
            guards = opts.delete(:guards) || []
            guards.concat view_keys
            @views['views'][method_name] = Proc.new {
              { 'map' => <<-JAVASCRIPT
function(doc) {
  if (#{([couchdb_types_condition] << guards).join(' && ')}) {
    emit(#{key_emit}, doc);
  }
}
JAVASCRIPT
              }
            }
          end
          @views['defaults'][method_name] = opts unless opts.empty?
          method_name
        end

        def views
          views = {}
          @views['views'].each_pair do |key, value|
            views[key] = value.call
          end
          views
        end

      end # ClassMethods

    end # Views
  end # Couch
end # DataMapper