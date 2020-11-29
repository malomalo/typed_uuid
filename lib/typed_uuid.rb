module TypedUUID
  autoload :ActiveRecord, 'typed_uuid/active_record'
  autoload :PsqlColumnMethods, 'typed_uuid/psql_column_methods'
  autoload :PsqlSchemaDumper, 'typed_uuid/psql_schema_dumper'
  
  def self.uuid(enum, version = 4)
    if enum < 0 || enum > 8_191
      raise ArgumentError, "UUID type must be between 0 and 8,191"
    end
    
    if version == 1
      timestamp_uuid(enum)
    elsif version == 4
      random_uuid(enum)
    end
  end
  
  def self.random_uuid(enum)
    uuid = SecureRandom.random_bytes(16).unpack("nnnnnnnn")
    
    uuid[4] = (uuid[3] ^ uuid[5]) ^ ((enum << 3) | 4)
    "%04x%04x-%04x-%04x-%04x-%04x%04x%04x" % uuid
  end

  def self.timestamp_uuid(enum)
    time = Time.now
    uuid = [time.to_i * 1_000_000_000 + time.nsec].pack('Q>')
    uuid << SecureRandom.random_bytes(8)

    uuid = uuid.unpack("nnnnnnnn")
    uuid[4] = (uuid[3] ^ uuid[5]) ^ ((enum << 3) | 1)
    "%04x%04x-%04x-%04x-%04x-%04x%04x%04x" % uuid
  end
  
  def self.enum(uuid)
    uuid = uuid.gsub('-', '')
    ((uuid[12..15].to_i(16) ^ uuid[20..23].to_i(16)) ^ uuid[16..19].to_i(16)) >> 3
  end
  
  def self.version(uuid)
    uuid = uuid.gsub('-', '')
    ((uuid[12..15].to_i(16) ^ uuid[20..23].to_i(16)) ^ uuid[16..19].to_i(16)) & 0b0000000000000111
  end
  
  def self.timestamp(uuid)
    uuid = uuid.gsub('-', '')
    Time.at(*uuid[0..15].to_i(16).divmod(1_000_000_000), :nsec)
  end
end

require 'typed_uuid/railtie' if defined? Rails
