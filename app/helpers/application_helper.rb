module ApplicationHelper
  def flash_message_class
    # TODO: Do this in a cleaner way
    flash[:alert] && flash[:alert] == 'Invalid email or password.' ?
      'alert error' : 'alert'
  end

  def impersonating?
    !session[:impersonation_user_id].blank?
  end
end
