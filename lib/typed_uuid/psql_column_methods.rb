module TypedUUID::PsqlColumnMethods

  def primary_key(name, type = :primary_key, **options)
    if type == :typed_uuid
      klass_type_enum = ::ActiveRecord::Base.uuid_enum_from_table_name(self.name)
      klass_type_version = ::ActiveRecord::Base.uuid_version_from_table_name(self.name)
      options[:default] ||= -> { "typed_uuid(#{klass_type_enum}, #{klass_type_version})" }
      super(name, :uuid, **options)
    else
      super
    end
  end

end