class SessionsController < ApplicationController
  skip_before_action :require_household_member, only: %i[new create]

  def new
  end

  def create
    member = HouseholdMember.find_by(username: params[:username].to_s.strip.downcase)

    if member&.authenticate(params[:password].to_s)
      reset_session
      session[:household_member_id] = member.id
      redirect_to household_members_path, notice: "Signed in."
    else
      flash.now[:alert] = "Username or password is incorrect."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to new_session_path, notice: "Signed out."
  end
end
