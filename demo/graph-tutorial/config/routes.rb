# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

Rails.application.routes.draw do
  get 'home/index'
  root 'home#index'

  # Add future routes here
end
