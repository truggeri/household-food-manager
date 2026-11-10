class HomeController < ApplicationController
  def index
    redirect_to household_members_path
  end
end
