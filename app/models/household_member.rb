class HouseholdMember < ApplicationRecord
  has_secure_password

  before_validation :normalize_attributes

  validates :name, presence: true, length: { maximum: 80 }
  validates :username, presence: true, length: { maximum: 40 },
    format: { with: /\A[a-z0-9][a-z0-9._-]*\z/ },
    uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 12 }, if: -> { password.present? }

  private

  def normalize_attributes
    self.name = name.to_s.strip
    self.username = username.to_s.strip.downcase
  end
end
