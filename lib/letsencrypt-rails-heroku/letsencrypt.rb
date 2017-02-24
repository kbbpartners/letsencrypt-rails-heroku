module Letsencrypt
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
  end

  def self.challenge_configured?
    configuration.acme_challenge_filename &&
      configuration.acme_challenge_filename.start_with?(".well-known/") &&
      configuration.acme_challenge_file_content
  end

  class Configuration
    attr_accessor :heroku_token, :heroku_app, :acme_email, :acme_domain, :acme_endpoint

    # Not settable by user; part of the gem's behaviour.
    attr_reader :acme_challenge_filename, :acme_challenge_file_content

    def initialize
      @heroku_token = ENV["HEROKU_TOKEN"]
      @heroku_app = ENV["HEROKU_APP"]
      @acme_email = ENV["ACME_EMAIL"]
      @acme_domain = ENV["ACME_DOMAIN"]
      @acme_endpoint = ENV["ACME_ENDPOINT"] || 'https://acme-v01.api.letsencrypt.org/'
    end

    def acme_challenge_filename
      puts "1 *!*!*! ENV['ACME_CHALLENGE_FILENAME']: #{ENV["ACME_CHALLENGE_FILENAME"]}"
      ENV["ACME_CHALLENGE_FILENAME"]
    end

    def update_challenge_filename(value)
      puts "2 *!*!*! acme_challenge_filename value: #{value}"
      write_attribute(:acme_challenge_filename, value)
    end

    def acme_challenge_file_content
      puts "3 *!*!*! ENV['ACME_CHALLENGE_FILE_CONTENT']: #{ENV["ACME_CHALLENGE_FILE_CONTENT"]}"
      ENV["ACME_CHALLENGE_FILE_CONTENT"]
    end

    def update_challenge_file_content(value)
      puts "4 *!*!*! acme_challenge_file_content value: #{value}"
      write_attribute(:acme_challenge_file_content, value)
    end

    def valid?
      heroku_token && heroku_app && acme_email
    end
  end
end
