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

  # Mail routes
  get 'mail', to: 'mail#index'
  get 'mail/new', to: 'mail#new'
  post 'mail/new', to: 'mail#create'
  get 'mail/:id', to: 'mail#show', as: 'show_mail'

  # Add route for OmniAuth callback
  match '/auth/:provider/callback', to: 'auth#callback', via: [:get, :post]
end
