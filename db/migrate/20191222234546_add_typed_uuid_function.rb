class AddTypedUuidFunction < ActiveRecord::Migration[6.0]
  def up
    if connection.is_a?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
      enable_extension 'pgcrypto'
    
      execute <<-SQL
        CREATE OR REPLACE FUNCTION typed_uuid(t bytea) RETURNS uuid AS $$
          DECLARE
            bytes bytea := gen_random_bytes(16);
            uuid bytea;
          BEGIN
            bytes := set_byte(bytes, 6, (get_byte(bytes, 4) # get_byte(bytes, 8)) # get_byte(t, 0));
            bytes := set_byte(bytes, 7, (get_byte(bytes, 5) # get_byte(bytes, 9)) # get_byte(t, 1));
            RETURN encode( bytes, 'hex') :: uuid;
          END;
        $$ LANGUAGE plpgsql;
      SQL
    end
  end
end