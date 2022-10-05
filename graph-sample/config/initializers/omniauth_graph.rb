# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
# frozen_string_literal: true

require 'microsoft_graph_auth'

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :microsoft_graph_auth,
           ENV.fetch('AZURE_APP_ID'),
           ENV.fetch('AZURE_APP_SECRET'),
           scope: ENV.fetch('AZURE_SCOPES')
end
