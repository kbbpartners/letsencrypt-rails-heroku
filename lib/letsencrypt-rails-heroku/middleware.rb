module Letsencrypt
  class Middleware

    def initialize(app)
      @app = app
    end

    def call(env)
      Rails.logger.info "Letsencrypt::Middleware called..."
      Rails.logger.info "LE 01A - Current path is #{env["PATH_INFO"]}"
      Rails.logger.info "LE 01B - Configuration path is #{Letsencrypt.configuration.acme_challenge_filename}"
      matching_paths = "/#{Letsencrypt.configuration.acme_challenge_filename}" == env["PATH_INFO"]
      if Letsencrypt.challenge_configured? && matching_paths
        return [200, {"Content-Type" => "text/plain"}, [Letsencrypt.configuration.acme_challenge_filename]]
      else
        Rails.logger.info "LE 01D - Current path and expected path match?"
        Rails.logger.info("LE 01E - Matching_paths: #{matching_paths}")
      end

      @app.call(env)
    end

  end
end
