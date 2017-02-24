module Letsencrypt
  class Middleware

    def initialize(app)
      @app = app
    end

    def call(env)
      current_path = env["PATH_INFO"]
      challenge_path = "/#{Letsencrypt.configuration.acme_challenge_filename}"
      matching_paths = current_path == challenge_path
      Rails.logger.info "LE 01A - env: #{env}"
      Rails.logger.info "LE 01B - matching_paths: #{matching_paths}"
      Rails.logger.info "LE 01C - current_path: #{current_path}"
      Rails.logger.info "LE 01D - challenge_path: #{challenge_path}"
      if Letsencrypt.challenge_configured? && matching_paths
        return [200, {"Content-Type" => "text/plain"}, [Letsencrypt.configuration.acme_challenge_file_content]]
      else
        Rails.logger.info "LE 01E - Current path and expected path match? #{matching_paths}"
      end

      @app.call(env)
    end

  end
end
