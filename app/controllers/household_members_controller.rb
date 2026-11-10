class HouseholdMembersController < ApplicationController
  def index
    @household_members = HouseholdMember.order(:name)
  end

  def new
    @household_member = HouseholdMember.new
  end

  def create
    @household_member = HouseholdMember.new(household_member_params)

    if @household_member.save
      redirect_to household_members_path, notice: "Household member added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def household_member_params
    params.require(:household_member).permit(:name, :username, :password, :password_confirmation)
  end
end
