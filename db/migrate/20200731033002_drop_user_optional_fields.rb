class DropUserOptionalFields < ActiveRecord::Migration[6.0]
  INDEX = [:user_optional_fields, [:label, :user_id], unique: true].freeze

  def up
    drop_table :user_optional_fields

    remove_index(*INDEX) if index_exists?(*INDEX)
  end

  def down
    create_table :user_optional_fields do |t|
      t.string :label, null: false
      t.string :value, null: false
      t.references :user, foreign_key: true, null: false

      t.timestamps
    end

    add_index(*INDEX) unless index_exists?(*INDEX)
  end
end

