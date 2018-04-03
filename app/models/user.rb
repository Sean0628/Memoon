class User < ApplicationRecord
  has_many :memos, dependent: :destroy

  validates :line_id, presence: true
end
