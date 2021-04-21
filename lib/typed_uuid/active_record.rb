require 'active_support/concern'

module TypedUUID::ActiveRecord
  extend ActiveSupport::Concern
  
  UUID_TYPE_CONFLICT_MESSAGE = \
    "You tried to define an UUID type %{int} for \"%{class_name}\", but " \
    " %{int} is already defined as the type for %{other}"

  included do
    class_attribute(:defined_uuid_types, instance_writer: false, default: {})
    class_attribute(:class_to_uuid_type_cache, instance_writer: false, default: Hash.new { |hash, klass|
      if type = defined_uuid_types.find { |k, v| v[:class] == klass.name }
        hash[klass] = type[1]
      end
    })
    class_attribute(:uuid_enum_to_class_cache, instance_writer: false, default: {})
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
    def register_uuid_type(class_name, enum_or_options)
      if enum_or_options.is_a?(Hash)
        enum = enum_or_options[:enum]
        version = enum_or_options[:version] || 4
      else
        enum = enum_or_options
        version = 4
      end
      
      if enum < 0 || enum > 8_191
        raise ArgumentError, "UUID type must be between 0 and 65,535"
      elsif defined_uuid_types.has_key?(enum)
        raise ArgumentError, UUID_TYPE_CONFLICT_MESSAGE % {
          int: enum,
          class_name: class_name,
          other: defined_uuid_types[enum]
        }
      else
        defined_uuid_types[enum] = { class: class_name.to_s, version: version, enum: enum }
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
    
    def typed_uuid(**options)
      TypedUUID.uuid(uuid_enum_from_class(self), uuid_version_from_class(self), **options)
    end
    
    def uuid_enum_from_table_name(table)
      uuid_enum_from_class(class_from_table_name(table))
    end

    def uuid_version_from_table_name(table)
      uuid_version_from_class(class_from_table_name(table))
    end
  
    def uuid_enum_from_class(klass)
      type = class_to_uuid_type_cache[klass]
      if type.nil?
        raise ArgumentError, "UUID Type for \"#{klass.name}\" not defined"
      end

      type[:enum]
    end

    def uuid_version_from_class(klass)
      type = class_to_uuid_type_cache[klass]
      if type.nil?
        raise ArgumentError, "UUID Type for \"#{klass.name}\" not defined"
      end

      type[:version]
    end

    def class_from_uuid_enum(enum)
      if uuid_enum_to_class_cache.has_key?(enum)
        uuid_enum_to_class_cache[enum]
      else
        Rails.application.eager_load! if !Rails.application.config.eager_load

        ::ActiveRecord::Base.descendants.each do |klass|
          next if klass.table_name.nil?
      
          if key = defined_uuid_types.find { |enum, info| info[:class] == klass.name }
            uuid_enum_to_class_cache[key[0]] = klass
          end
        end
      
        uuid_enum_to_class_cache[enum]
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
      class_from_uuid_enum(TypedUUID.enum(uuid))
    end
  end
  
end