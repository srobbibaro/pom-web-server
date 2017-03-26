class Api::ApiController < ActionController::Base
  before_action :doorkeeper_authorize!
  respond_to    :json

  def authenticated_user
    User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
  end
end
