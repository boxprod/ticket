# Stands in for a host app with Rails 8 authentication: a person in Current, a sign-in required.
class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  before_action :resume_session, :require_authentication

  private
    def resume_session
      Current.user = User.new(id: 7, name: session[:name], email_address: "#{session[:name]}@example.com") if session[:name]
    end

    def require_authentication
      head :unauthorized unless Current.user
    end
end
