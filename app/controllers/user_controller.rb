class UserController < ApplicationController
  before_filter :authenticate_user!

  def edit
    @user   = current_user
    @errors = []
  end

  def update
    @user   = User.find(current_user.id)
    @errors = []

    if params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
      params[:user].delete(:current_password)
    elsif !@user.valid_password?(params[:user][:current_password])
      @errors = [t('activerecord.errors.models.user.attributes.current_password.invalid')]
      render 'edit'
      return
    end

    if @user.update_attributes(user_params)
      sign_in @user, bypass: true
      redirect_to '/'
    else
      render 'edit'
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :display_name)
  end

end
