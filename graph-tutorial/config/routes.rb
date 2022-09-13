Rails.application.routes.draw do
  get 'home/index'
  root 'home#index'

# Add future routes here
# Add route for OmniAuth callback
match '/auth/:provider/callback', :to => 'auth#callback', :via => [:get, :post]
end
