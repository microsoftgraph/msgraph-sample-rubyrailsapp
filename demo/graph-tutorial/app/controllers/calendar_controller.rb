# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Calendar controller
class CalendarController < ApplicationController
  include GraphHelper

  def index
    # Get the IANA identifier of the user's time zone
    time_zone = get_iana_from_windows(user_timezone)

    # Calculate the start and end of week in the user's time zone
    start_datetime = Date.today.beginning_of_week(:sunday).in_time_zone(time_zone).to_time
    end_datetime = start_datetime.advance(:days => 7)

    @events = get_calendar_view access_token, start_datetime, end_datetime, user_timezone || []
  rescue RuntimeError => e
    @errors = [
      {
        :message => 'Microsoft Graph returned an error getting events.',
        :debug => e
      }
    ]
  end

  # <CreateEventRouteSnippet>
  def create
    # Semicolon-delimited list, split to an array
    attendees = params[:ev_attendees].split(';')

    # Create the event
    create_event access_token,
                 user_timezone,
                 params[:ev_subject],
                 params[:ev_start],
                 params[:ev_end],
                 attendees,
                 params[:ev_body]

    # Redirect back to the calendar list
    redirect_to({ :action => 'index' })
  rescue RuntimeError => e
    @errors = [
      {
        :message => 'Microsoft Graph returned an error creating the event.',
        :debug => e
      }
    ]
  end
  # </CreateEventRouteSnippet>
end
