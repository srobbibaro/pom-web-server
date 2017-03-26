class UserAdminController < ApplicationController
  before_filter :authenticate_user!, :check_admin!, except: [:halt_impersonate_user]
  before_filter :authenticate_user!, :check_non_impersonation_admin!, only: [:halt_impersonate_user]

  def index
    @users = User.all
  end

  def edit
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      flash[:success] = "Created user number #{@user.id}"
      redirect_to user_index_path
    else
      render 'new'
    end
  end

  def update
    @user = User.find(params[:id])

    params[:user].delete(:password) if params[:user][:password].blank?

    if @user.update_attributes(user_params)
      flash[:success] = "Updated user number #{@user.id}"
      redirect_to user_index_path
    else
      render 'edit'
    end
  end

  def destroy
    @user = User.find(params[:id])

    if @user.destroy
      flash[:success] = "Deleted user number #{@user.id}"
    else
      flash[:success] = "Could not delete user number #{@user.id}"
    end

    redirect_to user_index_path
  end

  def impersonate_user
    session[:impersonation_user_id] = params[:user_id]
    redirect_to '/'
  end

  def halt_impersonate_user
    session[:impersonation_user_id] = nil
    redirect_to '/'
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :display_name)
  end

  def check_admin!
    render text: "You are not authorized for this action!", status: :unauthorized unless current_user.admin?
  end

  def check_non_impersonation_admin!
    render text: "You are not authorized for this action!", status: :unauthorized unless devise_current_user.admin?
  end

end
