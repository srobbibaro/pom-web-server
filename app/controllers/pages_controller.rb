class PagesController < ApplicationController
  def auth_success
    render layout: 'devise'
    authenticate_user!
  end
end
