# TypedUUID

A __Typed UUID__ is an UUID with an enum embeded within the UUID.

UUIDs are 128bit or 16bytes. The hex format is represented below where x is
a hex representation of 4 bits.

`xxxxxxxx-xxxx-Mxxx-Nxxx-xxxxxxxxxxxx`

- M is 4 bits and is the Version
- N is 3 bits and is the Variant of the Version followed a bit

We modify this and use the following structure where the 15th & 16th bytes in the
UUID are the enum XORed with the result of XORing bytes 5 & 6 with bytes 13 & 14.

`xxxxxxxx-YYYY-xxxx-xxxx-xxxxZZZZTTTT`

Where:

- TTTT is the Type ENUM & Version 0bEEEE_EEEE_EEEE_EVVV; XORed with (YYYY xor ZZZZ)
    - The Es are the bits of the 13 bit ENUM supporting 8,192 enums/types (0 - 8,191)
    - The Vs are the bits in the 3 bit version supporting 8 versions (0 - 7)
- YYYY bytes XORed with ZZZZ and the Type ENUM to produce the identifying bytes
- ZZZZ bytes XORed with YYYY and the Type ENUM to produce the identifying bytes

XORing bytes 5 & 6 with 13 & 14 and XORing again with bytes 15 & 16 of the
Typed UUID will give us back the ENUM and Version of the Type using soley the UUID.

## Versions

As with regular UUID Typed UUIDs come in multiple version. The current versions are:

- Version 1: A timebased UUID where the first 56 bits are an unsigned integer
             representing the microseconds since epoch. Followed by 48 random
             bits or a sequence counter. Then 8 random bits followed by 16 bits
             which are the UUID type.

- Version 3: A name-based UUID where the first 112 bits are based off the MD5
             digest of the namespace and name. The following 16 bits are the
             UUID type.

- Version 4: A random UUID where the first 112 bits are random. The following
             16 bits are the UUID type.

- Version 5: A name-based UUID where the first 112 bits are based off the SHA1
             digest of the namespace and name. The following 16 bits are the
             UUID type.

## Install

Add this to your Gemfile:

`gem 'typed_uuid'`

Once bundled you can add an initializer to Rails to register your types as shown
below. This maps the __Model Classes__ to an integer between 0 and 65,535.

```ruby
# config/initializers/uuid_types.rb

ActiveRecord::Base.register_uuid_types({
  Listing: 	                0,
  Address:                  {enum: 5},
  Building:                 {enum: 512, version: 1},
  'Building::SkyScrpaer' => 8_191
})

# Or:

ActiveRecord::Base.register_uuid_types({
  0         => :Listing,
  512       => :Building,
  8_191    => 'Building::SkyScrpaer'
})
```


## Usage

In your migrations simply replace `id: :uuid` with `id: :typed_uuid` when creating
a table.

```ruby
class CreateProperties < ActiveRecord::Migration[5.2]
  def change
	create_table :properties, id: :typed_uuid do |t|
      t.string "name", limit: 255
    end
  end
end
```

To add a typed UUID to an existing table:

```ruby
class UpdateProperties < ActiveRecord::Migration[6.1]
  def change
    klass_enum = ::ActiveRecord::Base.uuid_type_from_table_name(:properties)

    # Add the column
    add_column :properties, :typed_uuid, :uuid, default: -> { "typed_uuid('\\x#{klass_enum.to_s(16).rjust(4, '0')}')" }

    # Update existing properties with a new typed UUID
    execute "UPDATE properties SET id = typed_uuid('\\x#{klass_enum.to_s(16).rjust(4, '0')}');"

    # Add null constraint since we'll swap these out for the primary key
    change_column_null :properties, :typed_uuid, false

    # TODO: Here you will want to update any reference to the old primary key
    # with the new typed_uuid that will be the new primary key.

    # Replace the old primary key with the typed_uuid
    execute "ALTER TABLE properties DROP CONSTRAINT properties_pkey;"
    rename_column :properties, :typed_uuid, :id
    execute "ALTER TABLE properties ADD PRIMARY KEY (id);"
  end
```

## STI Models
When using STI Model Rails will generate the UUID to be inserted. This UUID will
be calculated of the STI Model class and not the base class.

In the migration you can still used `id: :typed_uuid`, this will use the base
class to calculated the default type for the UUID. You could also set the
`id` to `:uuid` and the `default` to `false` so when no ID is given it will error.
