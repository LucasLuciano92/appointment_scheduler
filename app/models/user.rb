class User < ApplicationRecord
  has_secure_password

  has_many :admin_sessions, dependent: :destroy
  after_update :revoke_admin_sessions, if: :admin_access_changed?

  has_many :appointments, foreign_key: :customer_id, inverse_of: :customer,
    dependent: :restrict_with_error

  enum :role, { customer: 0, admin: 1 }, validate: true
  normalizes :email_address, with: ->(value) { value.strip.downcase }

  validates :first_name, :last_name, :email_address, presence: true
  validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP },
    uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :active, inclusion: { in: [ true, false ] }

  private

  def admin_access_changed?
    saved_change_to_password_digest? || (saved_change_to_active? && !active?) || (saved_change_to_role? && !admin?)
  end

  def revoke_admin_sessions
    admin_sessions.reset.destroy_all
  end
end
