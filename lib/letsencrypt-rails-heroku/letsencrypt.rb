module Letsencrypt
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
  end

  def self.challenge_configured?
    self.configuration.challenge_filename &&
      self.configuration.challenge_filename.start_with?(".well-known/") &&
      self.configuration.challenge_file_content
  end

  def self.update_challenge(filename, file_content)
    self.configuration.challenge_filename = filename
    self.configuration.challenge_file_content = file_content
  end

  class Configuration
    attr_accessor :heroku_token, :heroku_app, :acme_email, :acme_domain, :acme_endpoint, :challenge_filename, :challenge_file_content

    def initialize
      @heroku_token = ENV["HEROKU_TOKEN"]
      @heroku_app = ENV["HEROKU_APP"]
      @acme_email = ENV["ACME_EMAIL"]
      @acme_domain = ENV["ACME_DOMAIN"]
      @acme_endpoint = ENV["ACME_ENDPOINT"] || 'https://acme-v01.api.letsencrypt.org/'
    end

    def valid?
      heroku_token && heroku_app && acme_email
    end
  end
end
