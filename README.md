# TypedUUID

A __Typed UUID__ is an UUID with an enum embeded within the UUID.

UUIDs are 128bit or 16bytes. The hex format is represented below where x is
a hex representation of 4 bits.

`xxxxxxxx-xxxx-Mxxx-Nxxx-xxxxxxxxxxxx`

Where:

- M is 4 bits and is the Version
- N is 3 bits and is the Variant of the Version followed a bit

We modify this and use the following structure where the 7th & 8th bytes in the
UUID are enum XORed with bytes 5 & 6.

`xxxxxxxx-YYYY-TTTT-xxxx-xxxxxxxxxxxx`

Where:

- TTTT is the Class ENUM 0bNNNN_NNNN_NNNN_NNNN (0 - 65,535) XORed with YYYY
- YYYY are the bytes to be XORed with the Class ENUM to produce the identifying
  bytes

XORing bytes 7 & 8 with bytes 5 & 6 of the Typed UUID will give us back the ENUM
of the Type using soley the UUID.

## Install

Add this to your Gemfile:

`gem 'typed_uuid'`

Once bundled you can add an initializer to Rails to register your types as shown
below. This maps the __table_names__ of the models to an integer between 0 and 255.

```ruby
# config/initializers/uuid_types.rb

ActiveRecord::Base.register_uuid_types({
  listings: 	0,
  buildings: 	65_535
})

# Or:

ActiveRecord::Base.register_uuid_types({
  0 		=> :listings,
  65_535 	=> :buildings
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