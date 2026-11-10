class ApplicationController < ActionController::Base
  before_action :require_household_member

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_household_member

  private

  def current_household_member
    @current_household_member ||= HouseholdMember.find_by(id: session[:household_member_id])
  end

  def require_household_member
    return if current_household_member

    redirect_to new_session_path, alert: "Sign in to access your household."
  end
end
