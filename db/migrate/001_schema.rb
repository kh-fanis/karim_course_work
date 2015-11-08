class Schema < ActiveRecord::Migration
  def change
    create_table :items, force: true do |t|
      t.belongs_to :category
      t.string     :name
      t.text       :description
      t.float      :price
      t.string     :barcode
    end
    create_table :categories, force: true do |t|
      t.string :name
    end
  end
end