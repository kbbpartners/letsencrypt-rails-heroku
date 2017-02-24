module Letsencrypt
  class Middleware

    def initialize(app)
      @app = app
    end

    def call(env)
      Rails.logger.info "Letsencrypt::Middleware called..."
      Rails.logger.info "LE 01A - Current path is #{env["PATH_INFO"]}"
      Rails.logger.info "LE 01B - Expected challenge path is #{Letsencrypt.configuration.acme_challenge_filename}"
      Rails.logger.info "LE 01C - Expected challenge content is #{Letsencrypt.configuration.acme_challenge_file_content}"
      Rails.logger.info "LE 01D - ENV['ACME_CHALLENGE_FILENAME'] - #{ENV["ACME_CHALLENGE_FILENAME"]}"
      if Letsencrypt.challenge_configured? && env["PATH_INFO"] == "/#{Letsencrypt.configuration.acme_challenge_filename}"
        return [200, {"Content-Type" => "text/plain"}, [Letsencrypt.configuration.acme_challenge_file_content]]
      end

      @app.call(env)
    end

  end
end
