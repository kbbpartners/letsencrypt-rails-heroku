module Letsencrypt
  class Middleware

    def initialize(app)
      @app = app
    end

    def call(env)
      matching_paths = "/#{Letsencrypt.configuration.acme_challenge_filename}" == env["PATH_INFO"]
      if Letsencrypt.challenge_configured? && matching_paths
        return [200, {"Content-Type" => "text/plain"}, [Letsencrypt.configuration.acme_challenge_file_content]]
      end

      @app.call(env)
    end

  end
end
