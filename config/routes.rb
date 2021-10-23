Rails.application.routes.draw do
  use_doorkeeper_openid_connect scope: 'auth/openid'
  use_doorkeeper scope: 'auth/openid'
  devise_for :users
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
