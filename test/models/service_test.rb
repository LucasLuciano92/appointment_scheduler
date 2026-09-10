require "test_helper"

class ServiceTest < ActiveSupport::TestCase
  test "accepts a free service with positive integer duration" do
    service = Service.new(name: " Consultation ", duration_minutes: 30, price: 0)
    assert service.save
    assert_equal "Consultation", service.reload.name
    assert service.active?
  end

  test "rejects missing name invalid duration negative price and nil activation" do
    service = Service.new(name: " ", duration_minutes: 0, price: -1, active: nil)
    assert_not service.valid?
    %i[name duration_minutes price active].each { |attribute| assert service.errors[attribute].any? }
    service.duration_minutes = 1.5
    assert_not service.valid?
    assert service.errors[:duration_minutes].any?
  end

  test "model and database enforce unique names and valid numeric values" do
    service = Service.create!(name: "Haircut", duration_minutes: 30, price: 100)
    duplicate = Service.new(name: " HAIRCUT ", duration_minutes: 60, price: 200)
    assert_not duplicate.valid?
    assert duplicate.errors[:name].any?
    assert_raises(ActiveRecord::StatementInvalid) { service.update_columns(duration_minutes: 0) }
    assert_raises(ActiveRecord::StatementInvalid) { service.update_columns(price: -1) }
    service.reload
    assert_raises ActiveRecord::RecordNotUnique do
      Service.insert_all!([ service.attributes.except("id").merge("name" => "HAIRCUT") ])
    end
  end
end
