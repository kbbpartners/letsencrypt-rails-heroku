module Letsencrypt
  class Middleware

    def initialize(app)
      @app = app
    end

    def call(env)
      Rails.logger.debug "Seeking challenge at /#{Letsencrypt.configuration.acme_challenge_filename}"
      if Letsencrypt.challenge_configured? && env["PATH_INFO"] == "/#{Letsencrypt.configuration.acme_challenge_filename}"
        Rails.logger.debug "Challenge accepted. Should return 200."
        return [200, {"Content-Type" => "text/plain"}, [Letsencrypt.configuration.acme_challenge_file_content]]
      else
        Rails.logger.debug "Challenge rejected. #{@app}"
      end

      @app.call(env)
    end

  end
end
