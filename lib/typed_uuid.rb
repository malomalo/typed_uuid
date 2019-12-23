module TypedUUID
  autoload :ActiveRecord, 'typed_uuid/active_record'
  autoload :PsqlColumnMethods, 'typed_uuid/psql_column_methods'
end

require 'typed_uuid/railtie' if defined? Rails
