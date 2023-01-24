require 'digest/sha1'

module TypedUUID
  MIGRATIONS_PATH = File.expand_path('../../db/migrate', __FILE__)
  
  autoload :ActiveRecord, 'typed_uuid/active_record'
  autoload :PsqlColumnMethods, 'typed_uuid/psql_column_methods'
  autoload :PsqlSchemaDumper, 'typed_uuid/psql_schema_dumper'

  class << self

    def uuid(enum, version = 4, **options)
      if enum < 0 || enum > 8_191
        raise ArgumentError, "UUID type must be between 0 and 8,191"
      end

      case version
      when 1
        timestamp_uuid(enum, **options)
      when 3
        namebased_uuid(enum, digester: Digest::MD5, **options)
      when 4
        random_uuid(enum, **options)
      when 5
        namebased_uuid(enum, digester: Digest::SHA1, **options)
      end
    end

    def random_uuid(enum)
      uuid = SecureRandom.random_bytes(16).unpack("nnnnnnnn")

      uuid[7] = (uuid[2] ^ uuid[6]) ^ ((enum << 3) | 4)
      "%04x%04x-%04x-%04x-%04x-%04x%04x%04x" % uuid
    end

    def timestamp_uuid(enum, timestamp: nil, sequence: nil)
      timestamp  ||= Time.now

      uuid = [timestamp.to_i * 1_000_000 + timestamp.usec].pack('Q>')[1..-1]
      uuid << if sequence.nil?
        SecureRandom.random_bytes(8)
      elsif sequence.is_a?(Integer)
        sequence = [sequence].pack("Q>")
        if sequence.bytesize == 8 && sequence[0] == "\x00"
          sequence[1..]
        else
          raise ArgumentError, 'Sequence must be less than 8 bytes'
        end
      elsif sequence.is_a?(String)
        raise ArgumentError, 'Sequence must be less than 8 bytes' if sequence.bytesize > 7
        sequence.b
      else
        raise ArgumentError, 'Unable to convert sequence to binary'
      end
      uuid << "\x00\x00"

      uuid = uuid.unpack("nnnnnnnn")
      uuid[7] = ((uuid[2] ^ uuid[6]) ^ ((enum << 3) | 1))
      "%04x%04x-%04x-%04x-%04x-%04x%04x%04x" % uuid
    end

    def namebased_uuid(enum, digester:, name:, namespace: "")
      uuid = digester.digest(name + namespace).unpack("nnnnnnnn")
      uuid[7] = (uuid[2] ^ uuid[6]) ^ ((enum << 3) | 5)
      "%04x%04x-%04x-%04x-%04x-%04x%04x%04x" % uuid
    end

    def enum(uuid)
      uuid = uuid.gsub('-', '')
      ((uuid[8..11].to_i(16) ^ uuid[24..27].to_i(16)) ^ uuid[28..31].to_i(16)) >> 3
    end

    def version(uuid)
      uuid = uuid.gsub('-', '')
      ((uuid[8..11].to_i(16) ^ uuid[24..27].to_i(16)) ^ uuid[28..31].to_i(16)) & 0b0000000000000111
    end

    def timestamp(uuid)
      uuid = uuid.gsub('-', '')
      Time.at(*uuid[0..13].to_i(16).divmod(1_000_000), :usec)
    end

    def sequence_b(uuid)
      uuid = uuid.gsub('-', '')
      uuid[14..30].scan(/.{4}/).map{|i| i.to_i(16) }.pack('n*').b[0..-2]
    end

    def sequence(uuid)
      ("\x00" + sequence_b(uuid)).unpack1('Q>')
    end

  end
end

require 'typed_uuid/railtie' if defined? Rails
