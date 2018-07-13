Rails.application.routes.draw do
  get 'home/index'
  root 'home#index'

  # Add future routes here
  get 'auth/signin'
  get 'auth/signout'

  # Add route for OmniAuth callback
  match '/auth/:provider/callback', to: 'auth#callback', via: [:get, :post]
end
