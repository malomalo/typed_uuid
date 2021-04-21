module TypedUUID
  autoload :ActiveRecord, 'typed_uuid/active_record'
  autoload :PsqlColumnMethods, 'typed_uuid/psql_column_methods'
  autoload :PsqlSchemaDumper, 'typed_uuid/psql_schema_dumper'
  
  def self.uuid(enum, version = 4, **options)
    if enum < 0 || enum > 8_191
      raise ArgumentError, "UUID type must be between 0 and 8,191"
    end
    
    if version == 1
      timestamp_uuid(enum, **options)
    elsif version == 4
      random_uuid(enum, **options)
    end
  end
  
  def self.random_uuid(enum)
    uuid = SecureRandom.random_bytes(16).unpack("nnnnnnnn")
    
    uuid[7] = (uuid[2] ^ uuid[6]) ^ ((enum << 3) | 4)
    "%04x%04x-%04x-%04x-%04x-%04x%04x%04x" % uuid
  end
  
  def self.timestamp_uuid(enum, timestamp: nil, sequence: nil)
    timestamp  ||= Time.now
    
    uuid = [timestamp.to_i * 1_000_000 + timestamp.usec].pack('Q>')[1..-1]
    uuid << (sequence&.pack('Q>') || SecureRandom.random_bytes(10))
    
    uuid = uuid.unpack("nnnnnnnn")
    uuid[7] = (uuid[2] ^ uuid[6]) ^ ((enum << 3) | 1)
    "%04x%04x-%04x-%04x-%04x-%04x%04x%04x" % uuid
  end
  
  def self.enum(uuid)
    uuid = uuid.gsub('-', '')
    ((uuid[8..11].to_i(16) ^ uuid[24..27].to_i(16)) ^ uuid[28..31].to_i(16)) >> 3
  end
  
  def self.version(uuid)
    uuid = uuid.gsub('-', '')
    ((uuid[8..11].to_i(16) ^ uuid[24..27].to_i(16)) ^ uuid[28..31].to_i(16)) & 0b0000000000000111
  end
  
  def self.timestamp(uuid)
    uuid = uuid.gsub('-', '')
    Time.at(*uuid[0..13].to_i(16).divmod(1_000_000), :usec)
  end
end

require 'typed_uuid/railtie' if defined? Rails