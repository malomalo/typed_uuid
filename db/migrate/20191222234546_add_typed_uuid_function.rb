class AddTypedUuidFunction < ActiveRecord::Migration[6.0]
  def up
    if connection.is_a?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
      enable_extension 'pgcrypto'
    
      execute <<-SQL
        CREATE OR REPLACE FUNCTION typed_uuid(enum int, version int default 4)
        RETURNS uuid AS $$
        DECLARE
          bytes bytea;
          type bytea;
        BEGIN
          IF version = 1 THEN
            bytes := decode(concat(
                to_hex((extract(epoch from clock_timestamp())*1000000000)::bigint),
                encode(gen_random_bytes(8), 'hex')
            ), 'hex');
          ELSE
            bytes := gen_random_bytes(16);
            version := 4;
          END IF;

          type := decode( lpad(to_hex(((enum << 3) | version)), 4, '0'), 'hex');
          bytes := set_byte(bytes, 8, (get_byte(bytes, 6) # get_byte(bytes, 10)) # get_byte(type, 0));
          bytes := set_byte(bytes, 9, (get_byte(bytes, 7) # get_byte(bytes, 11)) # get_byte(type, 1));
          
          RETURN encode( bytes, 'hex') :: uuid;
        END;
        $$ LANGUAGE plpgsql;
      SQL
    end
  end
end