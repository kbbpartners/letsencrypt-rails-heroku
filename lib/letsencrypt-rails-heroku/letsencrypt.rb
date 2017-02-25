module Letsencrypt
  class << self
    attr_accessor :configuration, :challenge
  end

  def self.configure
    self.configuration ||= Configuration.new
    self.challenge = Challenge.new
    yield(configuration) if block_given?
  end

  def self.challenge_configured?
    self.challenge.challenge_filename &&
      self.challenge.challenge_filename.start_with?(".well-known/") &&
      self.challenge.challenge_file_content
  end

  def self.update_challenge(filename, file_content)
    self.challenge = Challenge.new
    self.challenge.challenge_filename = filename
    self.challenge.challenge_file_content = file_content
  end

  class Configuration
    attr_accessor :heroku_token, :heroku_app, :acme_email, :acme_domain, :acme_endpoint

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

  class Challenge
    attr_accessor :challenge_filename, :challenge_file_content

    def initialize
      @challenge_filename = ENV["ACME_CHALLENGE_FILENAME"]
      @challenge_file_content = ENV["ACME_CHALLENGE_FILE_CONTENT"]
    end
  end
end
