# Build Ruby on Rails apps with Microsoft Graph

In this lab you will create a Ruby on Rails web application using the Azure AD v2 authentication endpoint to access data in Office 365 using Microsoft Graph.

## In this lab

- [Create a Ruby on Rails web app](#exercise-1-create-a-ruby-on-rails-web-app)
- [Exercise 2: Register a web application with the Application Registration Portal](#exercise-2-register-a-web-application-with-the-application-registration-portal)
- [Extend the app for Azure AD Authentication](#exercise-3-extend-the-app-for-azure-ad-authentication)
- [Extend the app for Microsoft Graph](#exercise-4-extend-the-app-for-microsoft-graph)

## Prerequisites

To complete this lab, you need the following:

- [Ruby](https://www.ruby-lang.org/en/downloads/) installed on your development machine. If you do not have Ruby, visit the previous link for download options. (**Note:** This tutorial was written with Ruby version 2.4.4. The steps in this guide may work with other versions, but that has not been tested.)
- Either a personal Microsoft account with a mailbox on Outlook.com, or a Microsoft work or school account.

If you don't have a Microsoft account, there are a couple of options to get a free account:

- You can [sign up for a new personal Microsoft account](https://signup.live.com/signup?wa=wsignin1.0&rpsnv=12&ct=1454618383&rver=6.4.6456.0&wp=MBI_SSL_SHARED&wreply=https://mail.live.com/default.aspx&id=64855&cbcxt=mai&bk=1454618383&uiflavor=web&uaid=b213a65b4fdc484382b6622b3ecaa547&mkt=E-US&lc=1033&lic=1).
- You can [sign up for the Office 365 Developer Program](https://developer.microsoft.com/office/dev-program) to get a free Office 365 subscription.

## Exercise 1: Create a Ruby on Rails web app

In this exercise you will use [Ruby on Rails](https://rubyonrails.org/) to build a web app. If you don't already have Rails installed, you can install it from your command-line interface (CLI) with the following command.

```Shell
gem install rails
```

Open your CLI, navigate to a directory where you have rights to create files, and run the following command to create a new Rails app.

```Shell
rails new graph-tutorial
```

Rails creates a new directory called `graph-tutorial` and scaffolds a Rails app. Navigate to this new directory and enter the following command to start a local web server.

```Shell
rails server
```

Open your browser and navigate to `http://localhost:3000`. If everything is working, you will see a "Yay! You're on Rails!" message. If you don't see that message, check the [Rails getting started guide](http://guides.rubyonrails.org/).

Before moving on, install some additional gems that you will use later:

- [omniauth-oauth2](https://github.com/omniauth/omniauth-oauth2) for handling sign-in and OAuth token flows.
- [httparty](https://github.com/jnunemaker/httparty) for making calls to Microsoft Graph.
- [nokogiri](https://github.com/sparklemotion/nokogiri) to process HTML bodies of email.
- [activerecord-session_store](https://github.com/rails/activerecord-session_store) for storing sessions in the database.

Run the following commands in your CLI.

```Shell
bundle add omniauth-oauth2
bundle add httparty
bundle add nokogiri
bundle add activerecord-session_store
rails generate active_record:session_migration
```

The last command generates output like the following:

```Shell
create  db/migrate/20180618172216_add_sessions_table.rb
```

Open the file that was created and locate the following line.

```ruby
class AddSessionsTable < ActiveRecord::Migration
```

Change that line to the following.

```ruby
class AddSessionsTable < ActiveRecord::Migration[5.2]
```

> **Note:** This assumes that you are using Rails 5.2.x. If you are using a different version, replace `5.2` with your version.

Save the file and run the following command.

```Shell
rake db:migrate
```

Finally, configure Rails to use the new session store. Create a new file called `session_store.rb` in the `./config/initializers` directory, and add the following code.

```ruby
Rails.application.config.session_store :active_record_store, key: '_graph_app_session'
```

## Design the app

Start by updating the global layout for the app. Open `./app/views/layouts/application.html.erb` and replace its contents with the following.

```html
<!DOCTYPE html>
<html>
  <head>
    <title>Ruby Graph Tutorial</title>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.1.1/css/bootstrap.min.css" integrity="sha384-WskhaSGFgHYWDcbwN70/dfYBj47jz9qbsMId/iRN3ewGhXQFZCSftd1LZCfmhktB" crossorigin="anonymous">
    <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.1.0/css/all.css" integrity="sha384-lKuwvrZot6UHsBSfcMvOkWwlCMgc0TaWr+30HWe3a4ltaBwTZhyTEggF5tJv8tbt" crossorigin="anonymous">
    <script src="https://code.jquery.com/jquery-3.3.1.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.3/umd/popper.min.js" integrity="sha384-ZMP7rVo3mIykV+2+9J3UJ46jBk0WLaUAdn689aCwoqbBJiSnjAK/l8WvCWPIPm49" crossorigin="anonymous"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.1.1/js/bootstrap.min.js" integrity="sha384-smHYKdLADwkXOn1EmN1qk/HfnUcbVRZyYmZ4qpPea6sjB/pTJ0euyQp0Mk8ck+5T" crossorigin="anonymous"></script>
    <%= stylesheet_link_tag    'application', media: 'all', 'data-turbolinks-track': 'reload' %>
    <%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload' %>
  </head>

  <body>
    <nav class="navbar navbar-expand-md navbar-dark fixed-top bg-dark">
      <div class="container">
        <%= link_to "Ruby Graph Tutorial", root_path, class: "navbar-brand" %>
        <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarCollapse" aria-controls="navbarCollapse" aria-expanded="false" aria-label="Toggle navigation">
          <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="navbarCollapse">
          <ul class="navbar-nav mr-auto">
            <li class="nav-item">
              <%= link_to "Home", root_path, class: "nav-link#{' active' if controller.controller_name == 'home'}" %>
            </li>
            <% if @user_name %>
              <li class="nav-item" data-turbolinks="false">
                <a class="nav-link" href="#">Calendar</a>
              </li>
            <% end %>
          </ul>
          <ul class="navbar-nav justify-content-end">
            <% if @user_name %>
              <li class="nav-item dropdown">
                <a class="nav-link dropdown-toggle" data-toggle="dropdown" href="#" role="button" aria-haspopup="true" aria-expanded="false">
                  <% if @user_avatar %>
                    <img src=<%= @user_avatar %> class="rounded-circle align-self-center mr-2" style="width: 32px;">
                  <% else %>
                    <i class="far fa-user-circle fa-lg rounded-circle align-self-center mr-2" style="width: 32px;"></i>
                  <% end %>
                </a>
                <div class="dropdown-menu dropdown-menu-right">
                  <h5 class="dropdown-item-text mb-0"><%= @user_name %></h5>
                  <p class="dropdown-item-text text-muted mb-0"><%= @user_email %></p>
                  <div class="dropdown-divider"></div>
                  <a href="#" class="dropdown-item">Sign Out</a>
                </div>
              </li>
            <% else %>
              <li class="nav-item">
                <a href="#" class="nav-link">Sign In</a>
              </li>
            <% end %>
          </ul>
        </div>
      </div>
    </nav>
    <main role="main" class="container">
      <% if @errors %>
        <% @errors.each do |error| %>
          <div class="alert alert-danger" role="alert">
            <p class="mb-3"><%= error[:message] %></p>
            <%if error[:debug] %>
              <pre class="alert-pre border bg-light p-2"><code><%= error[:debug] %></code></error>
            <% end %>
          </div>
        <% end %>
      <% end %>
      <%= yield %>
    </main>
  </body>
</html>
```

This code adds [Bootstrap](http://getbootstrap.com/) for simple styling, and [Font Awesome](https://fontawesome.com/) for some simple icons. It also defines a global layout with a nav bar.

Now open `./app/assets/stylesheets/application.css` and add the following to the end of the file.

```css
body {
  padding-top: 4.5rem;
}

.alert-pre {
  word-wrap: break-word;
  word-break: break-all;
  white-space: pre-wrap;
}
```

Now replace the default page with a new one. Generate a home page controller with the following command.

```Shell
rails generate controller Home index
```

Then configure the `index` action on the `Home` controller as the default page for the app. Open `./config/routes.rb` and replace the contents with the following

```ruby
Rails.application.routes.draw do
  get 'home/index'
  root 'home#index'

  # Add future routes here

end
```

Now open the `./app/view/home/index.html.erb` file and replace its contents with the following.

```html
<div class="jumbotron">
  <h1>Ruby Graph Tutorial</h1>
  <p class="lead">This sample app shows how to use the Microsoft Graph API to access Outlook and OneDrive data from Ruby</p>
  <% if @user_name %>
    <h4>Welcome <%= @user_name %>!</h4>
    <p>Use the navigation bar at the top of the page to get started.</p>
  <% else %>
    <a href="#" class="btn btn-primary btn-large">Click here to sign in</a>
  <% end %>
</div>
```

Save all of your changes and restart the server. Now, the app should look very different.

![A screenshot of the redesigned home page](/Images/create-app-01.png)

## Exercise 2: Register a web application with the Application Registration Portal

In this exercise, you will create a new Azure AD web application registration using the Application Registry Portal (ARP).

1. Open a browser and navigate to the [Application Registry Portal](https://apps.dev.microsoft.com). Login using a **personal account** (aka: Microsoft Account) or **Work or School Account**.

1. Select **Add an app** at the top of the page.

    > **Note:** If you see more than one **Add an app** button on the page, select the one that corresponds to the **Converged apps** list.

1. On the **Register your application** page, set the **Application Name** to **Ruby on Rails Graph Tutorial** and select **Create**.

    ![Screenshot of creating a new app in the App Registration Portal website](/Images/arp-create-app-01.png)

1. On the **Ruby on Rails Graph Tutorial Registration** page, under the **Properties** section, copy the **Application Id** as you will need it later.

    ![Screenshot of newly created application's ID](/Images/arp-create-app-02.png)

1. Scroll down to the **Application Secrets** section.

    1. Select **Generate New Password**.
    1. In the **New password generated** dialog, copy the contents of the box as you will need it later.

        > **Important:** This password is never shown again, so make sure you copy it now.

    ![Screenshot of newly created application's password](/Images/arp-create-app-03.png)

1. Scroll down to the **Platforms** section.

    1. Select **Add Platform**.
    1. In the **Add Platform** dialog, select **Web**.

        ![Screenshot creating a platform for the app](/Images/arp-create-app-04.png)

    1. In the **Web** platform box, enter the URL `http://localhost:3000/auth/microsoft_graph_auth/callback` for the **Redirect URLs**.

        ![Screenshot of the newly added Web platform for the application](/Images/arp-create-app-05.png)

1. Scroll to the bottom of the page and select **Save**.

## Exercise 3: Extend the app for Azure AD Authentication

In this exercise you will extend the application from the previous exercise to support authentication with Azure AD. This is required to obtain the necessary OAuth access token to call the Microsoft Graph. You will integrate the [omniauth-oauth2](https://github.com/omniauth/omniauth-oauth2) gem into the application, and create a custom OmniAuth strategy.

First, create a separate file to hold your app ID and secret. Create a new file called `oauth_environment_variables.rb` in the `./config` folder, and add the following code.

```ruby
ENV['AZURE_APP_ID'] = 'YOUR APP ID HERE'
ENV['AZURE_APP_SECRET'] = 'YOUR APP SECRET HERE'
ENV['AZURE_SCOPES'] = 'openid profile email offline_access user.read calendars.read'
```

Replace `YOUR APP ID HERE` with the application ID from the Application Registration Portal, and replace `YOUR APP SECRET HERE` with the password you generated.

> **Tip:** If you're using source control such as git, now would be a good time to exclude the `oauth_environment_variables.rb` file from source control to avoid inadvertently leaking your app ID and password.

Now add code to load this file if it's present. Open the `./config/environment.rb` file and add the following code before the `Rails.application.initialize!` line.

```ruby
# Load OAuth settings
oauth_environment_variables = File.join(Rails.root, 'config', 'oauth_environment_variables.rb')
load(oauth_environment_variables) if File.exist?(oauth_environment_variables)
```

## Setup OmniAuth

You've already installed the `omniauth-oauth2` gem, but in order to make it work with the Azure OAuth endpoints, you need to [create an OAuth2 strategy](https://github.com/omniauth/omniauth-oauth2#creating-an-oauth2-strategy). This is a Ruby class that defines the parameters for making OAuth requests to the Azure provider.

Create a new file called `microsoft_graph_auth.rb` in the `./lib` folder, and add the following code.

```ruby
require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    # Implements an OmniAuth strategy to get a Microsoft Graph
    # compatible token from Azure AD
    class MicrosoftGraphAuth < OmniAuth::Strategies::OAuth2
      option :name, :microsoft_graph_auth

      DEFAULT_SCOPE = 'openid email profile User.Read'.freeze

      # Configure the Azure v2 endpoints
      option  :client_options,
              site:          'https://login.microsoftonline.com',
              authorize_url: '/common/oauth2/v2.0/authorize',
              token_url:     '/common/oauth2/v2.0/token'

      # Send the scope parameter during authorize
      option :authorize_options, [:scope]

      # Unique ID for the user is the id field
      uid { raw_info['id'] }

      # Get additional information after token is retrieved
      extra do
        {
          'raw_info' => raw_info
        }
      end

      def raw_info
        # Get user profile information from the /me endpoint
        @raw_info ||= access_token.get('https://graph.microsoft.com/v1.0/me').parsed
      end

      def authorize_params
        super.tap do |params|
          params['scope'.to_sym] = request.params['scope'] if request.params['scope']
          params[:scope] ||= DEFAULT_SCOPE
        end
      end

      # Override callback URL
      # OmniAuth by default passes the entire URL of the callback, including
      # query parameters. Azure fails validation because that doesn't match the
      # registered callback.
      def callback_url
        options[:redirect_uri] || (full_host + script_name + callback_path)
      end
    end
  end
end
```

Take a moment to review what this code does.

- It sets the `client_options` to specify the Azure v2 endpoints.
- It specifies that the `scope` parameter should be sent during the authorize phase.
- It maps the `id` property of the user as the unique ID for the user.
- It uses the access token to retrieve the user's profile from Microsoft Graph to fill in the `raw_info` hash.
- It overrides the callback URL to ensure that it matches the registered callback in the app registration portal.

Now that we've defined the strategy, we need to configure OmniAuth to use it. Create a new file called `omniauth_graph.rb` in the `./config/initializers` folder, and add the following code.

```ruby
require 'microsoft_graph_auth'

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :microsoft_graph_auth,
           ENV['AZURE_APP_ID'],
           ENV['AZURE_APP_SECRET'],
           scope: ENV['AZURE_SCOPES']
end
```

This code will execute when the app starts. It loads up the OmniAuth middleware with the `microsoft_graph_auth` provider, configured with the environment variables set in `oauth_environment_variables.rb`.

### Implement sign-in

Now that the OmniAuth middleware is configured, you can move on to adding sign-in to the app. Run the following command in your CLI to generate a controller for sign-in and sign-out.

```Shell
rails generate controller Auth
```

Open the `./app/controllers/auth_controller.rb` file. Add the following method to the `AuthController` class.

```ruby
def signin
  redirect_to '/auth/microsoft_graph_auth'
end
```

All this method does is redirect to the route that OmniAuth expects to invoke our custom strategy.

Next, add a callback method to the `AuthController` class. This method will be called by the OmniAuth middleware once the OAuth flow is complete.

```ruby
def callback
  # Access the authentication hash for omniauth
  data = request.env['omniauth.auth']

  # Temporary for testing!
  render json: data.to_json
end
```

For now all this does is render the hash provided by OmniAuth. We'll use this to verify that our sign-in is working before moving on. Before we test, we need to add the routes to `./config/routes.rb`.

```ruby
get 'auth/signin'

# Add route for OmniAuth callback
match '/auth/:provider/callback', to: 'auth#callback', via: [:get, :post]
```

Now update the views to use the `signin` action. Open `./app/views/layouts/application.html.erb`. Replace the line `<a href="#" class="nav-link">Sign In</a>` with the following.

```html
<%= link_to "Sign In", {:controller => :auth, :action => :signin}, :class => "nav-link" %>
```

Open the `./app/views/home/index.html.erb` file and replace the `<a href="#" class="btn btn-primary btn-large">Click here to sign in</a>` line with the following.

```html
<%= link_to "Click here to sign in", {:controller => :auth, :action => :signin}, :class => "btn btn-primary btn-large" %>
```

Start the server and browse to `https://localhost:3000`. Click the sign-in button and you should be redirected to `https://login.microsoftonline.com`. Login with your Microsoft account and consent to the requested permissions. The browser redirects to the app, showing the hash generated by OmniAuth.

```json
{
  "provider": "microsoft_graph_auth",
  "uid": "eb52b3b2-c4ac-4b4f-bacd-d5f7ece55df0",
  "info": {
    "name": null
  },
  "credentials": {
    "token": "eyJ0eXAi...",
    "refresh_token": "OAQABAAA...",
    "expires_at": 1529517383,
    "expires": true
  },
  "extra": {
    "raw_info": {
      "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#users/$entity",
      "id": "eb52b3b2-c4ac-4b4f-bacd-d5f7ece55df0",
      "businessPhones": [
        "+1 425 555 0109"
      ],
      "displayName": "Adele Vance",
      "givenName": "Adele",
      "jobTitle": "Retail Manager",
      "mail": "AdeleV@contoso.onmicrosoft.com",
      "mobilePhone": null,
      "officeLocation": "18/2111",
      "preferredLanguage": "en-US",
      "surname": "Vance",
      "userPrincipalName": "AdeleV@contoso.onmicrosoft.com"
    }
  }
}
```

### Storing the tokens

Now that you can get tokens, it's time to implement a way to store them in the app. Since this is a sample app, for simplicity's sake, you'll store them in the session. A real-world app would use a more reliable secure storage solution, like a database.

Open the `./app/controllers/application_controller.rb` file. You'll add all of our token management methods here. Because all of the other controllers inherit the `ApplicationController` class, they'll be able to use these methods to access the tokens.

Add the following method to the `ApplicationController` class. The method takes the OmniAuth hash as a parameter and extracts the relevant bits of information, then stores that in the session.

```ruby
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
```

Now add accessor functions to retrieve the user name, email address, and access token back out of the session.

```ruby
def user_name
  session[:user_name]
end

def user_email
  session[:user_email]
end

def access_token
  session[:graph_token_hash][:token]
end
```

Finally, add some code that will run before any action is processed.

```ruby
before_action :set_user

def set_user
  @user_name = user_name
  @user_email = user_email
end
```

This method sets the variables that the layout (in `application.html.erb`) uses to show the user's information in the nav bar. By adding it here, you don't have to add this code in every single controller action. However, this will also run for actions in the `AuthController`, which isn't optimal. Add the following code to the `AuthController` class in `./app/controllers/auth_controller.rb` to skip the before action.

```ruby
skip_before_action :set_user
```

Then, update the `callback` function in the `AuthController` class to store the tokens in the session and redirect back to the main page. Replace the existing `callback` function with the following.

```ruby
def callback
  # Access the authentication hash for omniauth
  data = request.env['omniauth.auth']

  # Save the data in the session
  save_in_session data

  redirect_to root_url
end
```

### Implement sign-out

Before you test this new feature, add a way to sign out. Add the following action to the `AuthController` class.

```ruby
def signout
  reset_session
  redirect_to root_url
end
```

Add this action to `./config/routes.rb`.

```ruby
get 'auth/signout'
```

Now update the view to use the `signout` action. Open `./app/views/layouts/application.html.erb`. Replace the line `<a href="#" class="dropdown-item">Sign Out</a>` with:

```html
<%= link_to "Sign Out", {:controller => :auth, :action => :signout}, :class => "dropdown-item" %>
```

Restart the server and go through the sign-in process. You should end up back on the home page, but the UI should change to indicate that you are signed-in.

![A screenshot of the home page after signing in](/Images/add-aad-auth-01.png)

Click the user avatar in the top right corner to access the **Sign Out** link. Clicking **Sign Out** resets the session and returns you to the home page.

![A screenshot of the dropdown menu with the Sign Out link](/Images/add-aad-auth-02.png)

### Refreshing tokens

If you look closely at the hash generated by OmniAuth, you'll notice there are two tokens in the hash: `token` and `refresh_token`. The value in `token` is the access token, which is sent in the `Authorization` header of API calls. This is the token that allows the app to access the Microsoft Graph on the user's behalf.

However, this token is short-lived. The token expires an hour after it is issued. This is where the `refresh_token` value becomes useful. The refresh token allows the app to request a new access token without requiring the user to sign in again. Update the token management code to implement token refresh.

Open `./app/controllers/application_controller.rb` and add the following `require` statements at the top:

```ruby
require 'microsoft_graph_auth'
require 'oauth2'
```

Then add the following method to the `ApplicationController` class.

```ruby
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
```

This method uses the [oauth2](https://github.com/oauth-xx/oauth2) gem (a dependency of the `omniauth-oauth2` gem) to refresh the tokens, and updates the session.

Now put this method to use. To do that, make the `access_token` accessor in the `ApplicationController` class a bit smarter. Instead of just returning the token from the session, it will first check if it is close to expiration. If it is, then it will refresh before returning the token. Replace the current `access_token` method with the following.

```ruby
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
```

## Exercise 4: Extend the app for Microsoft Graph

In this exercise you will incorporate the Microsoft Graph into the application. For this application, you will use the [httparty](https://github.com/jnunemaker/httparty) gem to make calls to Microsoft Graph.

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