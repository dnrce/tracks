class AddNextReviewPreferences < ActiveRecord::Migration[5.2]

  def self.up
    add_column :preferences, :review_period, :integer, :default => 14, :null => false
  end

  def self.down
    remove_column :preferences, :review_period
  end
end
