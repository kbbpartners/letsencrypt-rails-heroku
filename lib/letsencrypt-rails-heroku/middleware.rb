module Letsencrypt
  class Middleware

    def initialize(app)
      @app = app
    end

    def call(env)
      current_path = env["PATH_INFO"]
      challenge_path = "/#{Letsencrypt.configuration.acme_challenge_filename}"
      matching_paths = current_path == challenge_path
      Rails.logger.info "LE 01A - matching_paths: #{matching_paths}"
      if Letsencrypt.challenge_configured? && matching_paths
        return [200, {"Content-Type" => "text/plain"}, [Letsencrypt.configuration.acme_challenge_file_content]]
      else
        Rails.logger.info "LE 01B - Current path and expected path match? #{matching_paths}"
      end

      @app.call(env)
    end

  end
end
