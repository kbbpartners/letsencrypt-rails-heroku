module Letsencrypt
  class Middleware

    def initialize(app)
      @app = app
    end

    def call(env)
      puts "Letsencrypt::Middleware called..."
      puts "LE 01A - Current path is #{env["PATH_INFO"]}"
      puts "LE 01B - Expected challenge path is #{Letsencrypt.configuration.acme_challenge_filename}"
      puts "LE 01C - Challenge configured? #{Letsencrypt.challenge_configured?}"
      if Letsencrypt.challenge_configured? && env["PATH_INFO"] == "/#{Letsencrypt.configuration.acme_challenge_filename}"
        return [200, {"Content-Type" => "text/plain"}, [Letsencrypt.configuration.acme_challenge_file_content]]
      else
        puts "ER 01A - Current path is #{env["PATH_INFO"]}"
        puts "ER 01B - Expected challenge path is #{Letsencrypt.configuration.acme_challenge_filename}"
        puts "ER 01C - Challenge configured? #{Letsencrypt.challenge_configured?}"
      end

      @app.call(env)
    end

  end
end
