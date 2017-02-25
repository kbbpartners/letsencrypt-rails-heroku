module Letsencrypt
  class Middleware

    def initialize(app)
      @app = app
    end

    def call env
      dup._call env
    end

    def _call(env)
      current_path = env["PATH_INFO"]
      challenge_filename = "/#{Letsencrypt.configuration.acme_challenge_filename}"
      challenge_file_content = "#{Letsencrypt.configuration.acme_challenge_file_content}"
      matching_paths = current_path == challenge_filename

      Rails.logger.info "LE 01A - Open path: #{current_path}"
      Rails.logger.info "LE 01B - Challenge path: #{challenge_filename}"
      Rails.logger.info "LE 01C - Challenge response expected: #{challenge_file_content}"
      Rails.logger.info "LE 01D - ENV value is #{ENV["ACME_CHALLENGE_FILENAME"]}"

      if Letsencrypt.challenge_configured? && matching_paths
        return [200, {"Content-Type" => "text/plain"}, [Letsencrypt.configuration.acme_challenge_file_content]]
      else
        Rails.logger.info "LE 01D - Current path and expected path match? #{matching_paths}"
      end

      @app.call(env)
    end

  end
end
