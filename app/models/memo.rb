class Memo < ApplicationRecord
  belongs_to :user

  validates :title, :body, presence: true
  validates :title, length: { maximum: 40 }
  validates :body,  length: { maximum: 60 }
end
