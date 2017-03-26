class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  layout :layout_by_resource

  def layout_by_resource
    if devise_controller?
      "devise"
    else
      "application"
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  alias_method :devise_current_user, :current_user
  def current_user
    if session[:impersonation_user_id].blank?
      devise_current_user
    else
      devise_current_user.admin? ? User.find(session[:impersonation_user_id]) : nil
    end
  end
end
