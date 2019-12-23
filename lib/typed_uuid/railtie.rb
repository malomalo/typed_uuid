class TypedUUID::Railtie < Rails::Railtie

  initializer :typed_uuid do |app|
    ActiveSupport.on_load(:active_record) do
      ActiveRecord::Base.extend TypedUUID::ActiveRecord
    end
    
    require 'active_record/connection_adapters/postgresql/schema_definitions'    
    ActiveRecord::ConnectionAdapters::PostgreSQL::TableDefinition.include TypedUUID::PsqlColumnMethods
  end

end