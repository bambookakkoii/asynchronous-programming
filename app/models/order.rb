class Order < ApplicationRecord
  enum status: { pending: 0, paid: 1, completed: 2, cancelled: 3 }
end
