# frozen_string_literal: true

require_relative "spec/dummy/config/environment"

run Rails.application
Rails.application.load_server
