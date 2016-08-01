# frozen_string_literal: true
class LeaveApplication < ApplicationRecord
  before_save :calculate_hours
  belongs_to :user
  belongs_to :manager, class_name: "User", foreign_key: "manager_id"
  validates_presence_of :leave_type, :description
  acts_as_paranoid

  LEAVE_TYPE = %i(annual bonus personal sick).freeze

  include AASM
  include SignatureConcern

  aasm column: :status do
    state :pending, initial: true
    state :approved
    state :rejected
    state :closed

    event :approve, after: proc { |manager| sign(manager) } do
      transitions to: :approved, from: [:pending, :rejected]
    end

    event :reject, after: proc { |manager| sign(manager) } do
      transitions to: :rejected, from: [:pending, :approved]
    end

    event :revise do
      transitions to: :pending, from: [:pending, :approved, :rejected]
    end

    event :close do
      transitions to: :closed, from: [:pending, :approved, :rejected]
    end
  end

  scope :get_scope, ->(current_user) { current_user == "manager" ?  all : where(user_id: current_user.id) }

  private

  def calculate_hours
    self.hours = ( end_time - start_time ) / 3600.0
    puts end_time
  end
end
