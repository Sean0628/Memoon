class User < ApplicationRecord
  has_many :memos, dependent: :destroy
end
