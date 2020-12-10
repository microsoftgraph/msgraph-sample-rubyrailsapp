# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# <ConfigureOmniAuthSnippet>
require 'microsoft_graph_auth'

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :microsoft_graph_auth,
           ENV['AZURE_APP_ID'],
           ENV['AZURE_APP_SECRET'],
           :scope => ENV['AZURE_SCOPES']
end
# </ConfigureOmniAuthSnippet>
