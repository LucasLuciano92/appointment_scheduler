class ServiceOffering < ApplicationRecord
  belongs_to :staff_member
  belongs_to :service

  has_many :appointments, dependent: :restrict_with_error

  validates :service_id, uniqueness: { scope: :staff_member_id }
  validates :active, inclusion: { in: [ true, false ] }
  validate :preserve_booked_offering, on: :update

  private

  def preserve_booked_offering
    if (will_save_change_to_staff_member_id? || will_save_change_to_service_id?) && appointments.exists?
      errors.add(:base, :booked_offering)
    end
  end
end
