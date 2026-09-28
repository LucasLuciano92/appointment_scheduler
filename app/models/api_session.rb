class ApiSession < ApplicationRecord
  TOKEN_BYTES = 32
  LIFETIME = 30.days

  belongs_to :user

  validates :token_digest, :expires_at, presence: true
  validates :token_digest, uniqueness: true

  scope :current, -> { where("expires_at > ?", Time.current) }

  def self.issue!(user)
    token = SecureRandom.urlsafe_base64(TOKEN_BYTES)
    session = create!(user: user, token_digest: digest(token), expires_at: LIFETIME.from_now)
    [ session, token ]
  end

  def self.authenticate(token)
    return if token.blank?

    current.includes(:user).find_by(token_digest: digest(token))
  end

  def usable?
    expires_at > Time.current && user.active? && user.customer?
  end

  def self.digest(token)
    Digest::SHA256.hexdigest(token)
  end

  private_class_method :digest
end
