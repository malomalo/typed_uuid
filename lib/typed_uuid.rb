module TypedUUID
  autoload :ActiveRecord, 'typed_uuid/active_record'
  autoload :PsqlColumnMethods, 'typed_uuid/psql_column_methods'
  autoload :PsqlSchemaDumper, 'typed_uuid/psql_schema_dumper'
  
  def self.uuid(enum)
    uuid = SecureRandom.random_bytes(16).unpack("NnnnnN")
    uuid[2] = (uuid[1] ^ uuid[3]) ^ enum
    "%08x-%04x-%04x-%04x-%04x%08x" % uuid
  end
  
  def self.enum(uuid)
    uuid = uuid.gsub('-', '')
    (uuid[8..11].to_i(16) ^ uuid[16..19].to_i(16)) ^ uuid[12..15].to_i(16)
  end
end

require 'typed_uuid/railtie' if defined? Rails
