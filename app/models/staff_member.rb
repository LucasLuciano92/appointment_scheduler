class StaffMember < ApplicationRecord
  has_many :service_offerings, dependent: :restrict_with_error
  has_many :services, through: :service_offerings
  has_many :appointments, through: :service_offerings
  has_many :availabilities, dependent: :destroy

  normalizes :email_address, with: ->(value) { value.strip.downcase.presence }

  validates :first_name, :last_name, presence: true
  validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP },
    uniqueness: { case_sensitive: false }, allow_nil: true
  validates :active, inclusion: { in: [ true, false ] }
end
