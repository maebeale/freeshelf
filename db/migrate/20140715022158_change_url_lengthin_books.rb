class ChangeUrlLengthinBooks < ActiveRecord::Migration
  def change
    change_column :books, :url, :string, :limit => 1064
  end
end
