class AddEditingPermissionsToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :allow_small_edits, :boolean, default: true
    add_column :articles, :allow_big_edits, :boolean, default: true
  end
end
