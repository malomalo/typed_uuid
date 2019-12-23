# TypedUUID

A __Typed UUID__ is an UUID with an enum embeded within the UUID.

UUIDs are 128bit or 16bytes. The hex format is represented below where x is a hex representation of 4 bits.

`xxxxxxxx-xxxx-Mxxx-Nxxx-xxxxxxxxxxxx`

Where:

- M is 4 bits and is the Version
- N is 3 bits and is the Variant of the Version followed a bit

We modify this and use the following structure and place the enum (1 byte / 8 bits) at the 7th byte in the UUID.

`xxxxxxxx-xxxx-TTxx-xxxx-xxxxxxxxxxxx`

Where:

- TT is the Class ENUM 0bNNNN_NNNN (0-255)

Using this enum it makes it possible to determine what model the UUID is just by the UUID.

## Install

Add this to your Gemfile:

`gem 'typed_uuid'`

Once bundled you can add an initializer to Rails to register your types as shown
below. This maps the __table_names__ of the models to an integer between 0 and 255.

```ruby
# config/initializers/uuid_types.rb

ActiveRecord::Base.register_uuid_types({
  listings: 0,
  buildings: 255
})

# Or:

ActiveRecord::Base.register_uuid_types({
  0 	=> :listings,
  255 	=> :buildings
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