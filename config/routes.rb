Rails.application.routes.draw do
  # Authentication
  use_doorkeeper
  devise_for :users, :skip => [:passwords, :registrations]
    as :user do
      namespace :user do
        patch 'update'
        get 'edit'
      end
      scope '/admin' do
        resources :user, :controller => 'user_admin'
        get 'impersonate_user', :controller => 'user_admin'
        post 'halt_impersonate_user', :controller => 'user_admin'
      end
    end

  # Pages
  get 'arrival_schedule/index'
  get 'arrival_schedule/check_location_test'
  get 'pages/auth_success'
  get 'notifications/index'

  # Pages API
  post 'arrival_schedule/locations'
  post 'arrival_schedule/schedule'
  post 'arrival_schedule/remove_schedule'
  post 'arrival_schedule/check_location'
  post 'arrival_schedule/process_locations'
  post 'location_check/location_checks'
  post 'location_check/find_location'

  # API
  namespace :api do
    namespace :v1 do
      post 'arrival_schedule/check_location'
      post 'arrival_schedule/process_locations'
      post 'arrival_schedule/active_locations'
    end
  end

  # Site root
  root 'arrival_schedule#index'
end
