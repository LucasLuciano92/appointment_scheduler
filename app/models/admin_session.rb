class AdminSession < ApplicationRecord
  belongs_to :user

  validates :expires_at, presence: true

  def usable?
    expires_at > Time.current && user.active? && user.admin?
  end
end
