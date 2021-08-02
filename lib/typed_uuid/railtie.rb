class TypedUUID::Railtie < Rails::Railtie

  initializer :typed_uuid do |app|
    ActiveRecord::Tasks::DatabaseTasks.migrations_paths << File.expand_path('../../../db/migrate', __FILE__)

    ActiveSupport.on_load(:active_record) do
      ActiveRecord::Base.include TypedUUID::ActiveRecord
    end

    require 'active_record/connection_adapters/postgresql/schema_definitions'
    ActiveRecord::ConnectionAdapters::PostgreSQL::TableDefinition.include(TypedUUID::PsqlColumnMethods)

    require 'active_record/connection_adapters/abstract/schema_dumper'
    require 'active_record/connection_adapters/postgresql/schema_dumper'
    ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaDumper.prepend(TypedUUID::PsqlSchemaDumper)
  end

end
