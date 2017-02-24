module Letsencrypt
  class Middleware

    def initialize(app)
      @app = app
    end

    def call(env)
      Rails.logger.info "Letsencrypt::Middleware called..."
      Rails.logger.info "LE 01A - Current path is #{env["PATH_INFO"]}"
      Rails.logger.info "LE 01B - Expected path is #{Letsencrypt.configuration.acme_challenge_filename}"
      Rails.logger.info "LE 01C - ENV['ACME_CHALLENGE_FILENAME'] - #{ENV["ACME_CHALLENGE_FILENAME"]}"
      if Letsencrypt.challenge_configured?
        return [200, {"Content-Type" => "text/plain"}, [ENV["ACME_CHALLENGE_FILE_CONTENT"]]]
      else
        Rails.logger.info "LE 01D - Current path and expected path match?"
        Rails.logger.info((env["PATH_INFO"] == "/#{ENV["ACME_CHALLENGE_FILENAME"]}") ? 'YES' : 'NO')
      end

      @app.call(env)
    end

  end
end
