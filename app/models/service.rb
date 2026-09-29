class Service < ApplicationRecord
  IMAGE_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  MAX_IMAGE_SIZE = 5.megabytes

  has_many :service_offerings, dependent: :restrict_with_error
  has_many :staff_members, through: :service_offerings
  has_one_attached :image

  normalizes :name, with: ->(value) { value.strip }

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :duration_minutes, numericality: { only_integer: true, greater_than: 0 }
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :active, inclusion: { in: [ true, false ] }
  validate :acceptable_image

  private

  def acceptable_image
    return unless image.attached?

    unless IMAGE_CONTENT_TYPES.include?(image.blob.content_type)
      errors.add(:image, "debe ser JPEG, PNG o WebP")
    end
    errors.add(:image, "debe pesar 5 MB o menos") if image.blob.byte_size > MAX_IMAGE_SIZE
  end
end
