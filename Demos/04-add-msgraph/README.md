# Extend the Ruby on Rails app for Microsoft Graph

In this demo you will incorporate the Microsoft Graph into the application. For this application, you will use the [httparty](https://github.com/jnunemaker/httparty) gem to make calls to Microsoft Graph.

## Create a Graph helper

Create a helper to manage all of your API calls. Run the following command in your CLI to generate the helper.

```Shell
rails generate helper Graph
```

Open the newly created `./app/helpers/graph_helper.rb` file and replace the contents with the following.

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

Let's start by adding the ability to view events on the user's calendar. In your CLI, run the following command to add a new controller.

```Shell
rails generate controller Calendar index
```

Now that we have the route available, update the **Calendar** link in the navbar in `./app/view/layouts/application.html.erb` to use it. Replace the line `<a class="nav-link" href="#">Calendar</a>` with the following.

```html
<%= link_to "Calendar", {:controller => :calendar, :action => :index}, class: "nav-link#{' active' if controller.controller_name == 'calendar'}" %>
```

Add a new method to the Graph helper to [list the user's events](https://developer.microsoft.com/en-us/graph/docs/api-reference/v1.0/api/user_list_events). Open `./app/helpers/graph_helper.rb` and add the following method to the `GraphHelper` module.

```ruby
def get_calendar_events(token)
  get_events_url = '/v1.0/me/events'

  query = {
    '$select': 'subject,organizer,start,end',
    '$orderby': 'createdDateTime DESC'
  }

  response = make_api_call get_events_url, token, query

  raise response.parsed_response.to_s || "Request returned #{response.code}" unless response.code == 200
  response.parsed_response['value']
end
```

Consider what this code is doing.

- The URL that will be called is `/v1.0/me/events`.
- The `$select` parameter limits the fields returned for each events to just those our view will actually use.
- The `$orderby` parameter sorts the results by the date and time they were created, with the most recent item being first.
- For a successful response, it returns the array of items contained in the `value` key.

Now you can test this. Open `./app/controllers/calendar_controller.rb` and update the `index` action to call this method and render the results.

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

Restart the server. Sign in and click the **Calendar** link in the nav bar. If everything works, you should see a JSON dump of events on the user's calendar.

## Display the results

Now you can add HTML and CSS to display the results in a more user-friendly manner.

Open `./app/views/calendar/index.html.erb` and replace its contents with the following.

```html
<h1>Calendar</h1>
<table class="table">
  <thead>
    <tr>
      <th scope="col">Organizer</th>
      <th scope="col">Subject</th>
      <th scope="col">Start</th>
      <th scope="col">End</th>
    </tr>
  </thead>
  <tbody>
    <% @events.each do |event| %>
      <tr>
        <td><%= event['organizer']['emailAddress']['name'] %></td>
        <td><%= event['subject'] %></td>
        <td><%= event['start']['dateTime'].to_time(:utc).localtime.strftime('%-m/%-d/%y %l:%M %p') %></td>
        <td><%= event['end']['dateTime'].to_time(:utc).localtime.strftime('%-m/%-d/%y %l:%M %p') %></td>
      </tr>
    <% end %>
  </tbody>
</table>
```

That will loop through a collection of events and add a table row for each one. Remove the `render json: @events` line from the `index` action in `./app/controllers/calendar_controller.rb` and the app should now render a table of events.

![A screenshot of the table of events](/Images/add-msgraph-01.png)

## Next steps

Now that you have a working app that calls Microsoft Graph, you can experiment and add new features. Visit the [Microsoft Graph documentation](https://developer.microsoft.com/graph/docs/concepts/overview) to see all of the data you can access with Microsoft Graph.