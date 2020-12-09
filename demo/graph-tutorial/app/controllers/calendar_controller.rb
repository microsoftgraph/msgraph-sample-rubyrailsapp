# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Calendar controller
class CalendarController < ApplicationController
  include GraphHelper

  def index
    # Get the IANA identifier of the user's time zone
    time_zone = get_iana_from_windows(user_timezone)

    # Calculate the start and end of week in the user's time zone
    startDateTime = Date.today.beginning_of_week(:sunday).in_time_zone(time_zone).to_time()
    endDateTime = startDateTime.advance(days: 7)

    @events = get_calendar_view access_token, startDateTime, endDateTime, user_timezone || []
  rescue RuntimeError => e
    @errors = [
      {
        message: 'Microsoft Graph returned an error getting events.',
        debug: e
      }
    ]
  end
end
