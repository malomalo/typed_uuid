module TypedUUID::PsqlColumnMethods

  def primary_key(name, type = :primary_key, **options)
    if type == :typed_uuid
      klass_enum = ::ActiveRecord::Base.uuid_type_from_table_name(self.name)
      options[:id] = :uuid
      options[:default] ||= -> {"encode( set_byte(gen_random_bytes(16), 6, #{klass_enum}), 'hex')::uuid"}
      super(name, :uuid, **options)
    else
      super
    end
  end

end