# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

Rails.application.routes.draw do
  get 'calendar/index'
  get 'calendar', :to => 'calendar#index'
  get 'calendar/new'
  post 'calendar/new', :to => 'calendar#create'
  get 'home/index'
  root 'home#index'

  # Add future routes here
  # Add route for OmniAuth callback
  match '/auth/:provider/callback', :to => 'auth#callback', :via => [:get, :post]
  get 'auth/signout'
end
