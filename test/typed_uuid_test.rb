require 'test_helper'

class FilterTest < ActiveSupport::TestCase

  schema do
    ActiveRecord::Base.register_uuid_types({
      'FilterTest::Listing'  => 0,
      'FilterTest::Building' => 592,
      'FilterTest::SkyScraper' => 1_952
    })
    
    create_table :listings, id: :typed_uuid do |t|
      t.string   "name", limit: 255
    end
    
    create_table :buildings, id: :typed_uuid do |t|
      t.string   "name", limit: 255
      t.string   "type", limit: 255
    end
  end
  
  class Listing < ActiveRecord::Base
  end
  
  class Building < ActiveRecord::Base
  end
  
  class SkyScraper < Building
  end

  class SingleFamilyHome < Building
  end
  
  class Property < ActiveRecord::Base
  end
  
  test 'adding primary key as a typed_uuid in a migration' do
    ActiveRecord::Base.register_uuid_types({
      1 => 'FilterTest::Property'
    })

    exprexted_sql = <<-SQL
      CREATE TABLE "properties" ("id" uuid DEFAULT typed_uuid('\\x0001') NOT NULL PRIMARY KEY, "name" character varying(255))
    SQL

    assert_sql exprexted_sql do
      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Migration.create_table :properties, id: :typed_uuid do |t|
          t.string   "name",                    limit: 255
        end
      end
    end
  end

  test 'typed_uuid' do
    assert_equal 512, TypedUUID.enum(TypedUUID.uuid(512))
    assert_equal FilterTest::Listing,    ::ActiveRecord::Base.class_from_uuid(Listing.typed_uuid)
    assert_equal FilterTest::Building,   ::ActiveRecord::Base.class_from_uuid(Building.typed_uuid)
    assert_equal FilterTest::SkyScraper, ::ActiveRecord::Base.class_from_uuid(SkyScraper.typed_uuid)
    
    assert_raises ArgumentError do
      ::ActiveRecord::Base.class_from_uuid(SingleFamilyHome.typed_uuid)
    end
  end
  
  test 'class_from uuid' do
    listing = Listing.create
    building = Building.create
    skyscraper = SkyScraper.create
    
    assert_equal FilterTest::Listing, ::ActiveRecord::Base.class_from_uuid(listing.id)
    assert_equal FilterTest::Building, ::ActiveRecord::Base.class_from_uuid(building.id)
    assert_equal FilterTest::SkyScraper, ::ActiveRecord::Base.class_from_uuid(skyscraper.id)

    assert_raises ArgumentError do
      SingleFamilyHome.create
    end
  end
  
  test 'uuid_type from table_name' do
    assert_equal 0, ::ActiveRecord::Base.uuid_type_from_table_name(:listings)
    assert_equal 0, ::ActiveRecord::Base.uuid_type_from_table_name('listings')
    assert_equal 592, ::ActiveRecord::Base.uuid_type_from_table_name(:buildings)
  end
  
  test 'uuid_type from class' do
    assert_equal 0, ::ActiveRecord::Base.uuid_type_from_class(Listing)
    assert_equal 0, ::ActiveRecord::Base.uuid_type_from_class(Listing)
    assert_equal 592, ::ActiveRecord::Base.uuid_type_from_class(Building)
    assert_equal 1_952, ::ActiveRecord::Base.uuid_type_from_class(SkyScraper)
  end
  
  test 'class from uuid_type' do
    assert_equal FilterTest::Listing, ::ActiveRecord::Base.class_from_uuid_type(0)
    assert_equal FilterTest::Building, ::ActiveRecord::Base.class_from_uuid_type(592)
    assert_equal FilterTest::SkyScraper, ::ActiveRecord::Base.class_from_uuid_type(1_952)
  end
  
end