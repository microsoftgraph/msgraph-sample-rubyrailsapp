---
page_type: sample
description: This sample demonstrates how to use the Microsoft Graph .NET SDK to access data in Office 365 from Ruby on Rails apps.
products:
- ms-graph
- microsoft-graph-calendar-api
- office-exchange-online
languages:
- ruby
---

# Microsoft Graph sample Ruby on Rails app

[![Ruby](https://github.com/microsoftgraph/msgraph-sample-rubyrailsapp/actions/workflows/ruby.yml/badge.svg)](https://github.com/microsoftgraph/msgraph-sample-rubyrailsapp/actions/workflows/ruby.yml) ![License.](https://img.shields.io/badge/license-MIT-green.svg)

This sample demonstrates how to use the Microsoft Graph REST API to access data in Office 365 from Ruby on Rails apps.

> **NOTE:** This sample was originally built from a tutorial published on the [Microsoft Graph tutorials](https://learn.microsoft.com/graph/tutorials) page. That tutorial has been removed.

## Prerequisites

To run the completed project in this folder, you need the following:

- [Ruby](https://www.ruby-lang.org/en/downloads/)
- [SQLite3](https://sqlite.org/index.html)

This sample was written for Ruby 3.1.2.

## Register a web application with the Azure Active Directory admin center

1. Open a browser and navigate to the [Azure Active Directory admin center](https://aad.portal.azure.com). Login using a **personal account** (aka: Microsoft Account) or **Work or School Account**.

1. Select **Azure Active Directory** in the left-hand navigation, then select **App registrations** under **Manage**.

1. Select **New registration**. On the **Register an application** page, set the values as follows.

    - Set **Name** to `Ruby Graph Tutorial`.
    - Set **Supported account types** to **Accounts in any organizational directory and personal Microsoft accounts**.
    - Under **Redirect URI**, set the first drop-down to `Web` and set the value to `http://localhost:3000/auth/microsoft_graph_auth/callback`.

1. Choose **Register**. On the **Ruby Graph Tutorial** page, copy the value of the **Application (client) ID** and save it, you will need it in the next step.

1. Select **Certificates & secrets** under **Manage**. Select the **New client secret** button. Enter a value in **Description** and select one of the options for **Expires** and choose **Add**.

1. Copy the client secret value before you leave this page. You will need it in the next step.

## Configure the sample

1. Rename the `./graph-sample/config/oauth_environment_variables.rb.example` file to `oauth_environment_variables.rb`.

1. Edit the `oauth_environment_variables.rb` file and make the following changes.
    1. Replace `YOUR_APP_ID_HERE` with the **Application Id** you got from the App Registration Portal.
    1. Replace `YOUR_APP_SECRET_HERE` with the secret you got from the App Registration Portal.

1. In your command-line interface (CLI), navigate to the `./graph-sample` directory and run the following command to install requirements.

    ```Shell
    bundle install
    ```

1. In your CLI, run the following command to initialize the app's database.

    ```Shell
    rake db:migrate
    ```

## Run the sample

1. Run the following command in your CLI to start the application.

    ```Shell
    rails server
    ```

1. Open a browser and browse to `http://localhost:3000`.

## Code of conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Disclaimer

**THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.**
