<!-- markdownlint-disable MD002 MD041 -->

In this exercise you will incorporate the Microsoft Graph into the application. For this application, you will use the [httparty](https://github.com/jnunemaker/httparty) gem to make calls to Microsoft Graph.

## Create a Graph helper

1. Create a helper to manage all of your API calls. Run the following command in your CLI to generate the helper.

    ```Shell
    rails generate helper Graph
    ```

1. Open **./app/helpers/graph_helper.rb** and replace the contents with the following.

    ```ruby
    require 'httparty'

    # Graph API helper methods
    module GraphHelper
      GRAPH_HOST = 'https://graph.microsoft.com'.freeze

      def make_api_call(endpoint, token, params = nil)
        headers = {
          Authorization: "Bearer #{token}"
        }

        query = params || {}

        HTTParty.get "#{GRAPH_HOST}#{endpoint}",
                     headers: headers,
                     query: query
      end
    end
    ```

Take a moment to review what this code does. It makes a simple GET request via the `httparty` gem to the requested endpoint. It sends the access token in the `Authorization` header, and it includes any query parameters that are passed.

For example, to use the `make_api_call` method to do a GET to `https://graph.microsoft.com/v1.0/me?$select=displayName`, you could call it like so:

```ruby
make_api_call `/v1.0/me`, access_token, { '$select': 'displayName' }
```

You'll build on this later as you implement more Microsoft Graph features into the app.

## Get calendar events from Outlook

1. In your CLI, run the following command to add a new controller.

    ```Shell
    rails generate controller Calendar index
    ```

1. Add the new route to **./config/routes.rb**.

    ```ruby
    get 'calendar', to: 'calendar#index'
    ```

1. Add a new method to the Graph helper to [list the user's events](/graph/api/user-list-events?view=graph-rest-1.0). Open **./app/helpers/graph_helper.rb** and add the following method to the `GraphHelper` module.

    :::code language="ruby" source="../demo/graph-tutorial/app/helpers/graph_helper.rb" id="GetCalendarSnippet":::

    Consider what this code is doing.

    - The URL that will be called is `/v1.0/me/events`.
    - The `$select` parameter limits the fields returned for each events to just those our view will actually use.
    - The `$orderby` parameter sorts the results by the date and time they were created, with the most recent item being first.
    - For a successful response, it returns the array of items contained in the `value` key.

1. Open **./app/controllers/calendar_controller.rb** and replace its entire contents with the following.

    ```ruby
    # Calendar controller
    class CalendarController < ApplicationController
      include GraphHelper

      def index
        @events = get_calendar_events access_token || []
        render json: @events
      rescue RuntimeError => e
        @errors = [
          {
            message: 'Microsoft Graph returned an error getting events.',
            debug: e
          }
        ]
      end
    end
    ```

1. Restart the server. Sign in and click the **Calendar** link in the nav bar. If everything works, you should see a JSON dump of events on the user's calendar.

## Display the results

Now you can add HTML to display the results in a more user-friendly manner.

1. Open **./app/views/calendar/index.html.erb** and replace its contents with the following.

    :::code language="html" source="../demo/graph-tutorial/app/views/calendar/index.html.erb" id="CalendarSnippet":::

    That will loop through a collection of events and add a table row for each one.

1. Remove the `render json: @events` line from the `index` action in **./app/controllers/calendar_controller.rb**.

1. Refresh the page and the app should now render a table of events.

    ![A screenshot of the table of events](./images/add-msgraph-01.png)
