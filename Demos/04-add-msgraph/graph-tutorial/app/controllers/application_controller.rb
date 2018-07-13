require 'microsoft_graph_auth'
require 'oauth2'

# Application controller
class ApplicationController < ActionController::Base
  before_action :set_user

  def set_user
    @user_name = user_name
    @user_email = user_email
  end

  def save_in_session(auth_hash)
    # Save the token info
    session[:graph_token_hash] = auth_hash.dig(:credentials)
    # Save the user's display name
    session[:user_name] = auth_hash.dig(:extra, :raw_info, :displayName)
    # Save the user's email address
    # Use the mail field first. If that's empty, fall back on
    # userPrincipalName
    session[:user_email] = auth_hash.dig(:extra, :raw_info, :mail) ||
                           auth_hash.dig(:extra, :raw_info, :userPrincipalName)
  end

  def user_name
    session[:user_name]
  end

  def user_email
    session[:user_email]
  end

  def access_token
    token_hash = session[:graph_token_hash]

    # Get the expiry time - 5 minutes
    expiry = Time.at(token_hash[:expires_at] - 300)

    if Time.now > expiry
      # Token expired, refresh
      new_hash = refresh_tokens token_hash
      new_hash[:token]
    else
      token_hash[:token]
    end
  end

  def refresh_tokens(token_hash)
    oauth_strategy = OmniAuth::Strategies::MicrosoftGraphAuth.new(
      nil, ENV['AZURE_APP_ID'], ENV['AZURE_APP_SECRET']
    )

    token = OAuth2::AccessToken.new(
      oauth_strategy.client, token_hash[:token],
      refresh_token: token_hash[:refresh_token]
    )

    # Refresh the tokens
    new_tokens = token.refresh!.to_hash.slice(:access_token, :refresh_token, :expires_at)

    # Rename token key
    new_tokens[:token] = new_tokens.delete :access_token

    # Store the new hash
    session[:graph_token_hash] = new_tokens
  end
end
