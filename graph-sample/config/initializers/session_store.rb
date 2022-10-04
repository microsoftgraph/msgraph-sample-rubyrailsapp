# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
# frozen_string_literal: true

Rails.application.config.session_store :active_record_store, key: '_graph_app_session'
