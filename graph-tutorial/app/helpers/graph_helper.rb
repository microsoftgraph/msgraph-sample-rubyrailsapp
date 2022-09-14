# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

require 'httparty'

# Graph API helper methods
module GraphHelper
  GRAPH_HOST = 'https://graph.microsoft.com'.freeze

  def make_api_call(method, endpoint, token, headers = nil, params = nil, payload = nil)
    headers ||= {}
    headers[:Authorization] = "Bearer #{token}"
    headers[:Accept] = 'application/json'

    params ||= {}

    case method.upcase
    when 'GET'
      HTTParty.get "#{GRAPH_HOST}#{endpoint}",
                   :headers => headers,
                   :query => params
    when 'POST'
      headers['Content-Type'] = 'application/json'
      HTTParty.post "#{GRAPH_HOST}#{endpoint}",
                    :headers => headers,
                    :query => params,
                    :body => payload ? payload.to_json : nil
    else
      raise "HTTP method #{method.upcase} not implemented"
    end
  end

  # <GetCalendarSnippet>
  def get_calendar_view(token, start_datetime, end_datetime, timezone)
    get_events_url = '/v1.0/me/calendarview'

    headers = {
      'Prefer' => "outlook.timezone=\"#{timezone}\""
    }

    query = {
      'startDateTime' => start_datetime.iso8601,
      'endDateTime' => end_datetime.iso8601,
      '$select' => 'subject,organizer,start,end',
      '$orderby' => 'start/dateTime',
      '$top' => 50
    }

    response = make_api_call 'GET', get_events_url, token, headers, query

    raise response.parsed_response.to_s || "Request returned #{response.code}" unless response.code == 200

    response.parsed_response['value']
  end
  # </GetCalendarSnippet>

  # <CreateEventSnippet>
  def create_event(token, timezone, subject, start_datetime, end_datetime, attendees, body)
    create_event_url = '/v1.0/me/events'

    # Create an event object
    # https://docs.microsoft.com/graph/api/resources/event?view=graph-rest-1.0
    new_event = {
      'subject' => subject,
      'start' => {
        'dateTime' => start_datetime,
        'timeZone' => timezone
      },
      'end' => {
        'dateTime' => end_datetime,
        'timeZone' => timezone
      }
    }

    unless attendees.empty?
      attendee_array = []
      # Create an attendee object
      # https://docs.microsoft.com/graph/api/resources/attendee?view=graph-rest-1.0
      attendees.each { |email| attendee_array.push({ 'type' => 'required', 'emailAddress' => { 'address' => email } }) }
      new_event['attendees'] = attendee_array
    end

    unless body.empty?
      # Create an itemBody object
      # https://docs.microsoft.com/graph/api/resources/itembody?view=graph-rest-1.0
      new_event['body'] = {
        'contentType' => 'text',
        'content' => body
      }
    end

    response = make_api_call 'POST',
                             create_event_url,
                             token,
                             nil,
                             nil,
                             new_event

    raise response.parsed_response.to_s || "Request returned #{response.code}" unless response.code == 201
  end
  # </CreateEventSnippet>
  
  # <ZoneMappingSnippet>
  TIME_ZONE_MAP = {
    'Dateline Standard Time' => 'Etc/GMT+12',
    'UTC-11' => 'Etc/GMT+11',
    'Aleutian Standard Time' => 'America/Adak',
    'Hawaiian Standard Time' => 'Pacific/Honolulu',
    'Marquesas Standard Time' => 'Pacific/Marquesas',
    'Alaskan Standard Time' => 'America/Anchorage',
    'UTC-09' => 'Etc/GMT+9',
    'Pacific Standard Time (Mexico)' => 'America/Tijuana',
    'UTC-08' => 'Etc/GMT+8',
    'Pacific Standard Time' => 'America/Los_Angeles',
    'US Mountain Standard Time' => 'America/Phoenix',
    'Mountain Standard Time (Mexico)' => 'America/Chihuahua',
    'Mountain Standard Time' => 'America/Denver',
    'Central America Standard Time' => 'America/Guatemala',
    'Central Standard Time' => 'America/Chicago',
    'Easter Island Standard Time' => 'Pacific/Easter',
    'Central Standard Time (Mexico)' => 'America/Mexico_City',
    'Canada Central Standard Time' => 'America/Regina',
    'SA Pacific Standard Time' => 'America/Bogota',
    'Eastern Standard Time (Mexico)' => 'America/Cancun',
    'Eastern Standard Time' => 'America/New_York',
    'Haiti Standard Time' => 'America/Port-au-Prince',
    'Cuba Standard Time' => 'America/Havana',
    'US Eastern Standard Time' => 'America/Indianapolis',
    'Turks And Caicos Standard Time' => 'America/Grand_Turk',
    'Paraguay Standard Time' => 'America/Asuncion',
    'Atlantic Standard Time' => 'America/Halifax',
    'Venezuela Standard Time' => 'America/Caracas',
    'Central Brazilian Standard Time' => 'America/Cuiaba',
    'SA Western Standard Time' => 'America/La_Paz',
    'Pacific SA Standard Time' => 'America/Santiago',
    'Newfoundland Standard Time' => 'America/St_Johns',
    'Tocantins Standard Time' => 'America/Araguaina',
    'E. South America Standard Time' => 'America/Sao_Paulo',
    'SA Eastern Standard Time' => 'America/Cayenne',
    'Argentina Standard Time' => 'America/Buenos_Aires',
    'Greenland Standard Time' => 'America/Godthab',
    'Montevideo Standard Time' => 'America/Montevideo',
    'Magallanes Standard Time' => 'America/Punta_Arenas',
    'Saint Pierre Standard Time' => 'America/Miquelon',
    'Bahia Standard Time' => 'America/Bahia',
    'UTC-02' => 'Etc/GMT+2',
    'Azores Standard Time' => 'Atlantic/Azores',
    'Cape Verde Standard Time' => 'Atlantic/Cape_Verde',
    'UTC' => 'Etc/GMT',
    'GMT Standard Time' => 'Europe/London',
    'Greenwich Standard Time' => 'Atlantic/Reykjavik',
    'Sao Tome Standard Time' => 'Africa/Sao_Tome',
    'Morocco Standard Time' => 'Africa/Casablanca',
    'W. Europe Standard Time' => 'Europe/Berlin',
    'Central Europe Standard Time' => 'Europe/Budapest',
    'Romance Standard Time' => 'Europe/Paris',
    'Central European Standard Time' => 'Europe/Warsaw',
    'W. Central Africa Standard Time' => 'Africa/Lagos',
    'Jordan Standard Time' => 'Asia/Amman',
    'GTB Standard Time' => 'Europe/Bucharest',
    'Middle East Standard Time' => 'Asia/Beirut',
    'Egypt Standard Time' => 'Africa/Cairo',
    'E. Europe Standard Time' => 'Europe/Chisinau',
    'Syria Standard Time' => 'Asia/Damascus',
    'West Bank Standard Time' => 'Asia/Hebron',
    'South Africa Standard Time' => 'Africa/Johannesburg',
    'FLE Standard Time' => 'Europe/Kiev',
    'Israel Standard Time' => 'Asia/Jerusalem',
    'Kaliningrad Standard Time' => 'Europe/Kaliningrad',
    'Sudan Standard Time' => 'Africa/Khartoum',
    'Libya Standard Time' => 'Africa/Tripoli',
    'Namibia Standard Time' => 'Africa/Windhoek',
    'Arabic Standard Time' => 'Asia/Baghdad',
    'Turkey Standard Time' => 'Europe/Istanbul',
    'Arab Standard Time' => 'Asia/Riyadh',
    'Belarus Standard Time' => 'Europe/Minsk',
    'Russian Standard Time' => 'Europe/Moscow',
    'E. Africa Standard Time' => 'Africa/Nairobi',
    'Iran Standard Time' => 'Asia/Tehran',
    'Arabian Standard Time' => 'Asia/Dubai',
    'Astrakhan Standard Time' => 'Europe/Astrakhan',
    'Azerbaijan Standard Time' => 'Asia/Baku',
    'Russia Time Zone 3' => 'Europe/Samara',
    'Mauritius Standard Time' => 'Indian/Mauritius',
    'Saratov Standard Time' => 'Europe/Saratov',
    'Georgian Standard Time' => 'Asia/Tbilisi',
    'Volgograd Standard Time' => 'Europe/Volgograd',
    'Caucasus Standard Time' => 'Asia/Yerevan',
    'Afghanistan Standard Time' => 'Asia/Kabul',
    'West Asia Standard Time' => 'Asia/Tashkent',
    'Ekaterinburg Standard Time' => 'Asia/Yekaterinburg',
    'Pakistan Standard Time' => 'Asia/Karachi',
    'Qyzylorda Standard Time' => 'Asia/Qyzylorda',
    'India Standard Time' => 'Asia/Calcutta',
    'Sri Lanka Standard Time' => 'Asia/Colombo',
    'Nepal Standard Time' => 'Asia/Katmandu',
    'Central Asia Standard Time' => 'Asia/Almaty',
    'Bangladesh Standard Time' => 'Asia/Dhaka',
    'Omsk Standard Time' => 'Asia/Omsk',
    'Myanmar Standard Time' => 'Asia/Rangoon',
    'SE Asia Standard Time' => 'Asia/Bangkok',
    'Altai Standard Time' => 'Asia/Barnaul',
    'W. Mongolia Standard Time' => 'Asia/Hovd',
    'North Asia Standard Time' => 'Asia/Krasnoyarsk',
    'N. Central Asia Standard Time' => 'Asia/Novosibirsk',
    'Tomsk Standard Time' => 'Asia/Tomsk',
    'China Standard Time' => 'Asia/Shanghai',
    'North Asia East Standard Time' => 'Asia/Irkutsk',
    'Singapore Standard Time' => 'Asia/Singapore',
    'W. Australia Standard Time' => 'Australia/Perth',
    'Taipei Standard Time' => 'Asia/Taipei',
    'Ulaanbaatar Standard Time' => 'Asia/Ulaanbaatar',
    'Aus Central W. Standard Time' => 'Australia/Eucla',
    'Transbaikal Standard Time' => 'Asia/Chita',
    'Tokyo Standard Time' => 'Asia/Tokyo',
    'North Korea Standard Time' => 'Asia/Pyongyang',
    'Korea Standard Time' => 'Asia/Seoul',
    'Yakutsk Standard Time' => 'Asia/Yakutsk',
    'Cen. Australia Standard Time' => 'Australia/Adelaide',
    'AUS Central Standard Time' => 'Australia/Darwin',
    'E. Australia Standard Time' => 'Australia/Brisbane',
    'AUS Eastern Standard Time' => 'Australia/Sydney',
    'West Pacific Standard Time' => 'Pacific/Port_Moresby',
    'Tasmania Standard Time' => 'Australia/Hobart',
    'Vladivostok Standard Time' => 'Asia/Vladivostok',
    'Lord Howe Standard Time' => 'Australia/Lord_Howe',
    'Bougainville Standard Time' => 'Pacific/Bougainville',
    'Russia Time Zone 10' => 'Asia/Srednekolymsk',
    'Magadan Standard Time' => 'Asia/Magadan',
    'Norfolk Standard Time' => 'Pacific/Norfolk',
    'Sakhalin Standard Time' => 'Asia/Sakhalin',
    'Central Pacific Standard Time' => 'Pacific/Guadalcanal',
    'Russia Time Zone 11' => 'Asia/Kamchatka',
    'New Zealand Standard Time' => 'Pacific/Auckland',
    'UTC+12' => 'Etc/GMT-12',
    'Fiji Standard Time' => 'Pacific/Fiji',
    'Chatham Islands Standard Time' => 'Pacific/Chatham',
    'UTC+13' => 'Etc/GMT-13',
    'Tonga Standard Time' => 'Pacific/Tongatapu',
    'Samoa Standard Time' => 'Pacific/Apia',
    'Line Islands Standard Time' => 'Pacific/Kiritimati'
  }.freeze

  def get_iana_from_windows(windows_tz_name)
    iana = TIME_ZONE_MAP[windows_tz_name]
    # If no mapping found, assume the supplied
    # value was already an IANA identifier
    iana || windows_tz_name
  end
  # </ZoneMappingSnippet>
end
