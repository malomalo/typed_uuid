module TypedUUID::PsqlSchemaDumper

  def extensions(stream)
    super(stream)
    stream.puts <<-RB
  ## These are functions that must be enabled in order to support typed_uuids
  ## in this database
  execute <<-SQL
    CREATE OR REPLACE FUNCTION typed_uuid(enum int, version int default 4)
    RETURNS uuid AS $$
    DECLARE
      bytes bytea;
      type bytea;
    BEGIN
      IF version = 1 THEN
        bytes := decode(concat(
            lpad(right(to_hex((extract(epoch from clock_timestamp())*1000000)::bigint), 12), 12, '0'),
            encode(gen_random_bytes(10), 'hex')
        ), 'hex');
      ELSE
        bytes := gen_random_bytes(16);
      END IF;

      type := decode( lpad(to_hex(((enum << 3) | version)), 4, '0'), 'hex');
      bytes := set_byte(bytes, 14, (get_byte(bytes, 4) # get_byte(bytes, 12)) # get_byte(type, 0));
      bytes := set_byte(bytes, 15, (get_byte(bytes, 5) # get_byte(bytes, 13)) # get_byte(type, 1));
    
      RETURN encode( bytes, 'hex') :: uuid;
    END;
    $$ LANGUAGE plpgsql;
  SQL

    RB
    stream
  end
  
end