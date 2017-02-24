module Letsencrypt
  class Middleware

    def initialize(app)
      @app = app
    end

    def call(env)
      if Letsencrypt.challenge_configured? && env["PATH_INFO"] == "/#{Letsencrypt.configuration.acme_challenge_filename}"
        return [200, {"Content-Type" => "text/plain"}, [Letsencrypt.configuration.acme_challenge_file_content]]
      else
        puts "Error 01A - Current path is #{env["PATH_INFO"]}"
        puts "Error 01B - Expected challenge path is #{Letsencrypt.configuration.acme_challenge_filename}"
        puts "Error 01C - Challenge configured? #{Letsencrypt.challenge_configured?}"
      end

      @app.call(env)
    end

  end
end
