module TypedUUID::ActiveRecord
  
  UUID_TYPE_CONFLICT_MESSAGE = \
    "You tried to define an UUID type %{int} for \"%{table}\", but " \
    " %{int} is already defined as the type for %{other}"
  
  def self.extended(base) # :nodoc:
    base.class_attribute(:defined_uuid_types, instance_writer: false, default: {})
    base.class_attribute(:uuid_type_cache, instance_writer: false, default: {})
  end
  
  def register_uuid_type(table, int)
    if int < 0 || int > 65_535
      raise ArgumentError, "UUID type must be between 0 and 65,535"
    elsif defined_uuid_types.has_key?(int)
      raise ArgumentError, UUID_TYPE_CONFLICT_MESSAGE % {
        int: int,
        table: table,
        other: defined_uuid_types[int]
      }
    else
      defined_uuid_types[int] = table.to_s
    end
  end
  
  def register_uuid_types(mapping)
    mapping.each do |k, v|
      if k.is_a?(Integer)
        register_uuid_type(v, k)
      else
        register_uuid_type(k, v)
      end
    end
  end

  def uuid_type_from_table_name(table)
    type = defined_uuid_types.key(table.to_s)
    if type.nil?
      raise ArgumentError, "UUID Type for \"#{table}\" not defined"
    end
    
    type
  end
  
  def class_from_uuid_type(type)
    if klass = uuid_type_cache[type]
      return klass 
    else
      # Rails.application.eager_load! if !Rails.application.config.eager_load

      ::ActiveRecord::Base.descendants.select do |klass|
        next unless ( klass.superclass == ::ActiveRecord::Base || klass.superclass.abstract_class? )
        next if klass.table_name.nil?
        
        uuid_type_cache[defined_uuid_types.key(klass.table_name)] = klass
      end
      
      uuid_type_cache[type]
    end
  end
  
  def class_from_uuid(uuid)
    uuid = uuid.gsub('-', '')
    class_from_uuid_type(uuid[8..11].to_i(16) ^ uuid[12..15].to_i(16))
  end
  
end