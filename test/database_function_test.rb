require 'test_helper'

class DatabaseFunctionTest < ActiveSupport::TestCase

  schema do
    ActiveRecord::Base.register_uuid_types({
      'DatabaseFunctionTest::Ship'  => {enum: 13, version: 1}
    })

    create_table :ships, id: :typed_uuid do |t|
      t.string   "name", limit: 255
    end
  end

  class Ship < ActiveRecord::Base
  end

  class Sailor < ActiveRecord::Base
  end

  class Sea < ActiveRecord::Base
  end

  test 'adding primary key as a typed_uuid in a migration' do
    ActiveRecord::Base.register_uuid_types({
      1 => 'DatabaseFunctionTest::Sailor'
    })

    exprexted_sql = <<-SQL
      CREATE TABLE "sailors" ("id" uuid DEFAULT typed_uuid(1, 4) NOT NULL PRIMARY KEY, "name" character varying(255))
    SQL

    assert_sql exprexted_sql do
      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Migration.create_table :sailors, id: :typed_uuid do |t|
          t.string   "name",                    limit: 255
        end
      end
    end
  end

  test 'adding primary key as a typed_uuid in a migration with a version' do
    ActiveRecord::Base.register_uuid_types({
      'DatabaseFunctionTest::Sea' => {version: 1, enum: 512}
    })

    exprexted_sql = <<-SQL
      CREATE TABLE "seas" ("id" uuid DEFAULT typed_uuid(512, 1) NOT NULL PRIMARY KEY, "name" character varying(255))
    SQL

    assert_sql exprexted_sql do
      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Migration.create_table :seas, id: :typed_uuid do |t|
          t.string   "name",                    limit: 255
        end
      end
    end
  end

  test 'typed_uuid(enum)' do
    uuid = ActiveRecord::Base.connection.execute('SELECT typed_uuid(13) AS uuid')[0]['uuid']
    
    assert_equal 13,                           TypedUUID.enum(uuid)
    assert_equal 4,                            TypedUUID.version(uuid)
    assert_equal DatabaseFunctionTest::Ship,   ::ActiveRecord::Base.class_from_uuid(uuid)
  end

  test 'typed_uuid(enum, 4)' do
    uuid = ActiveRecord::Base.connection.execute('SELECT typed_uuid(13, 4) AS uuid')[0]['uuid']
    
    assert_equal 13,                          TypedUUID.enum(uuid)
    assert_equal 4,                           TypedUUID.version(uuid)
    assert_equal DatabaseFunctionTest::Ship,  ::ActiveRecord::Base.class_from_uuid(uuid)
  end

  test 'typed_uuid(enum, 1)' do
    time = Time.now
    uuid = ActiveRecord::Base.connection.execute('SELECT typed_uuid(13, 1) AS uuid')[0]['uuid']
    
    assert_equal  13,                          TypedUUID.enum(uuid)
    assert_equal  1,                           TypedUUID.version(uuid)
    assert        (time.ceil(0) - TypedUUID.timestamp(uuid).ceil(0)).abs <= 1
    assert_equal  DatabaseFunctionTest::Ship,  ::ActiveRecord::Base.class_from_uuid(uuid)
  end

end
