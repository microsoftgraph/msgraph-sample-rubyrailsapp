# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
# frozen_string_literal: true

# Mail controller
class MailController < ApplicationController
  include GraphHelper

  def index
    # Get messages from inbox
    @messages = get_messages access_token, user_timezone || []
  rescue RuntimeError => e
    @messages = []
    @errors = [
      {
        message: 'Microsoft Graph returned an error getting messages.',
        debug: e
      }
    ]
  end

  def show
    # Get specific message
    @message = get_message access_token, params[:id], user_timezone
  rescue RuntimeError => e
    @message = nil
    @errors = [
      {
        message: 'Microsoft Graph returned an error getting the message.',
        debug: e
      }
    ]
    redirect_to action: 'index'
  end

  def new
    # Display new message form
    @recipients = []
  end

  def create
    # Semicolon-delimited list, split to an array
    recipients = params[:recipients].split(';')

    # Create the email
    send_mail access_token,
              recipients,
              params[:subject],
              params[:body]

    # Redirect back to the inbox
    redirect_to({ action: 'index' })
  rescue RuntimeError => e
    @errors = [
      {
        message: 'Microsoft Graph returned an error sending the mail.',
        debug: e
      }
    ]
    render 'new'
  end
end
