class Order < ApplicationRecord
  enum :status, { pending: 0, paid: 1, completed: 2, cancelled: 3 }

  scope :recent_day, ->(day) { where("created_at > ?", (day - 1).days.ago) }
end
