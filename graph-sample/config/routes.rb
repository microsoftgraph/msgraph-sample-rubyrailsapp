# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
# frozen_string_literal: true

Rails.application.routes.draw do
  get 'calendar/index'
  get 'calendar/new'
  get 'home/index'
  root 'home#index'
  get 'auth/signout'
  get 'calendar', to: 'calendar#index'
  post 'calendar/new', to: 'calendar#create'
  # Add route for OmniAuth callback
  match '/auth/:provider/callback', to: 'auth#callback', via: [:get, :post]
end
