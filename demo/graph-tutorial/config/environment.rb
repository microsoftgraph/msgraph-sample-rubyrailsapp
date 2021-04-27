# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# <LoadOAuthSettingsSnippet>
# Load the Rails application.
require_relative "application"

# Load OAuth settings
oauth_environment_variables = File.join(Rails.root, 'config', 'oauth_environment_variables.rb')
load(oauth_environment_variables) if File.exist?(oauth_environment_variables)

# Initialize the Rails application.
Rails.application.initialize!
# </LoadOAuthSettingsSnippet>
