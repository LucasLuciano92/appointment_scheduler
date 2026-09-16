class Service < ApplicationRecord
  has_many :service_offerings, dependent: :restrict_with_error
  has_many :staff_members, through: :service_offerings

  normalizes :name, with: ->(value) { value.strip }

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :duration_minutes, numericality: { only_integer: true, greater_than: 0 }
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :active, inclusion: { in: [ true, false ] }
end
