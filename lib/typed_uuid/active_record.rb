require 'active_support/concern'

module TypedUUID::ActiveRecord
  extend ActiveSupport::Concern
  
  UUID_TYPE_CONFLICT_MESSAGE = \
    "You tried to define an UUID type %{int} for \"%{class_name}\", but " \
    " %{int} is already defined as the type for %{other}"

  included do
    class_attribute(:defined_uuid_types, instance_writer: false, default: {})
    class_attribute(:class_to_uuid_type_cache, instance_writer: false, default: Hash.new { |hash, klass|
      hash[klass] = defined_uuid_types.key(klass.name)
    })
    class_attribute(:uuid_type_to_class_cache, instance_writer: false, default: {})
  end
  
  def _create_record
    klass = self.class
    if !klass.descends_from_active_record? && klass.typed?
      pk = klass.primary_key
      write_attribute(pk, klass.typed_uuid) if pk && read_attribute(pk).nil?
    end
    
    super
  end
  
  class_methods do
    def register_uuid_type(class_name, int)
      if int < 0 || int > 65_535
        raise ArgumentError, "UUID type must be between 0 and 65,535"
      elsif defined_uuid_types.has_key?(int)
        raise ArgumentError, UUID_TYPE_CONFLICT_MESSAGE % {
          int: int,
          class_name: class_name,
          other: defined_uuid_types[int]
        }
      else
        defined_uuid_types[int] = class_name.to_s
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

    def typed?
      !!class_to_uuid_type_cache[self.base_class]
    end
    
    def typed_uuid
      TypedUUID.uuid(uuid_type_from_class(self))
    end
  
    def uuid_type_from_table_name(table)
      uuid_type_from_class(class_from_table_name(table))
    end

    def uuid_type_from_class(klass)
      type = class_to_uuid_type_cache[klass]

      if type.nil?
        raise ArgumentError, "UUID Type for \"#{klass.name}\" not defined"
      end

      type
    end
  
    def class_from_uuid_type(type)
      klass = if uuid_type_to_class_cache.has_key?(type)
        uuid_type_to_class_cache[type]
      else
        Rails.application.eager_load! if !Rails.application.config.eager_load

        ::ActiveRecord::Base.descendants.each do |klass|
          next if klass.table_name.nil?
        
          uuid_type_to_class_cache[defined_uuid_types.key(klass.name)] = klass
        end
      
        uuid_type_to_class_cache[type]
      end
    end
  
    def class_from_table_name(table)
      table = table.to_s
      Rails.application.eager_load! if !Rails.application.config.eager_load
    
      ::ActiveRecord::Base.descendants.find do |klass|
        next unless ( klass.superclass == ::ActiveRecord::Base || klass.superclass.abstract_class? )
        next if klass.table_name.nil?

        klass.table_name == table
      end
    end
  
    def class_from_uuid(uuid)
      class_from_uuid_type(TypedUUID.enum(uuid))
    end
  end
  
end