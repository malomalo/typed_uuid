module TypedUUID::PsqlColumnMethods

  def primary_key(name, type = :primary_key, **options)
    if type == :typed_uuid
      klass_enum = ::ActiveRecord::Base.uuid_type_from_table_name(self.name)
      options[:id] = :uuid
      options[:default] ||= -> { "typed_uuid('\\x#{klass_enum.to_s(16).ljust(4, '0')}')" }
      super(name, :uuid, **options)
    else
      super
    end
  end

end