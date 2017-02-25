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
      challenge_filename = "/#{Letsencrypt.challenge.challenge_filename}"
      challenge_file_content = "#{Letsencrypt.challenge.challenge_file_content}"
      matching_paths = current_path == challenge_filename

      if Letsencrypt.challenge_configured? && matching_paths
        return [200, {"Content-Type" => "text/plain"}, [Letsencrypt.challenge.challenge_file_content]]
      else
        puts "LE 01A - Current path and expected path match? #{matching_paths}"
        puts "LE 01A - Challenge response expected: #{challenge_file_content}"
        puts "LE 01A - Challenge path: #{challenge_filename}"
        puts "LE 01A - Open path: #{current_path}"
      end

      @app.call(env)
    end

  end
end
