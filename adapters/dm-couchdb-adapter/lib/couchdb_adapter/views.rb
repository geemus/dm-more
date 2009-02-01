module DataMapper
  module Couch
    module Views

      def inherited(target)
        target.instance_variable_set(:@design_doc, @design_doc.dup)
      end

      def self.included(model)
        model.extend(ClassMethods)
        model.instance_variable_set(:@design_doc, CouchRest::Design.new(model.default_design_doc))
      end

      module ClassMethods

        def default_design_doc
          {
            'language' => 'javascript',
            'views' => {
              'all' => {
                'map' => "function(doc) {
                  if (#{couchdb_types_condition}) {
                    emit(#{key}, doc);
                  }
              }"
              }
            }
          }
        end

        def couchdb_types
          Proc.new { [self.base_model] | self.descendants }.call
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
            opts[:guards].push couchdb_types_condition
          end
          keys.push opts
          @design_doc.view_by(*keys)
        end
      end

    end
  end
end