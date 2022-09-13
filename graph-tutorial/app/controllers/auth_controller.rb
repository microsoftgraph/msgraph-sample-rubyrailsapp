class AuthController < ApplicationController

  # <CallbackSnippet>
  def callback
    # Access the authentication hash for omniauth
    data = request.env['omniauth.auth']

    # Save the data in the session
    save_in_session data

    redirect_to root_url
  end
  # </CallbackSnippet>

  
end