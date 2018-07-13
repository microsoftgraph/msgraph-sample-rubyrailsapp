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
end
