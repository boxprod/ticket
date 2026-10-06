class PagesController < ApplicationController
  skip_before_action :require_authentication

  def show
  end

  def sign_in
    session[:name] = params[:name]
    redirect_to root_path
  end
end
