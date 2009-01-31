module DataMapper
  module Couch
    module Views

      def self.included(mod)
        mod.class_eval do

          def default_design_doc
            {
              'language' => 'javascript',
              'views' => {
                'all' => {
                  'map' => "function(doc) {
                    if (#{couchdb_type_conditions}) {
                      emit(#{key}, doc);
                    }
                }"
                }
              }
            }
          end
        end
      end

    end
  end
end