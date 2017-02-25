require 'open-uri'
require 'openssl'
require 'acme-client'
require 'platform-api'

namespace :letsencrypt do

  desc 'Renew your LetsEncrypt certificate'
  task :renew do

    configuration = Letsencrypt.configuration

    # Check configuration looks OK
    abort "letsencrypt-rails-heroku is configured incorrectly. Are you missing an environment variable or other configuration? You should have a heroku_token, heroku_app and acme_email configured either via a `Letsencrypt.configure` block in an initializer or as environment variables." unless configuration.valid?

    # Set up Heroku client
    heroku = PlatformAPI.connect_oauth configuration.heroku_token
    heroku_app = configuration.heroku_app

    # Create a private key

    # print "Creating account key..."
    private_key = OpenSSL::PKey::RSA.new(4096)
    # puts "Done!"

    client = Acme::Client.new(private_key: private_key, endpoint: configuration.acme_endpoint, connection_options: { request: { open_timeout: 5, timeout: 5 } })

    # print "Registering with LetsEncrypt..."
    registration = client.register(contact: "mailto:#{configuration.acme_email}")

    registration.agree_terms
    # puts "Done!"

    domains = []
    if configuration.acme_domain
      # puts "Using ACME_DOMAIN configuration variable..."
      domains = configuration.acme_domain.split(',').map(&:strip)
    else
      domains = heroku.domain.list(heroku_app).map{|domain| domain['hostname']}
      puts "Using #{domains.length} configured Heroku domain(s) for this app..."
    end

    domains.each_with_index do |domain, attempt_number|
      puts "Performing verification for #{domain}:"
      attempt_domain = domain

      authorization = client.authorize(domain: domain)
      challenge = authorization.http01

      attempt_letsencrypt_config_filename_before_update = configuration.challenge_filename
      attempt_letsencrypt_config_file_content_before_update = configuration.challenge_file_content

      print "Setting config vars on Heroku... \n"
      attempt_challenge_filename_returned_from_acme = challenge.filename
      attempt_challenge_file_content_returned_from_acme = challenge.file_content

      update_result = heroku.config_var.update(heroku_app, {
        'ACME_CHALLENGE_FILENAME' => challenge.filename,
        'ACME_CHALLENGE_FILE_CONTENT' => challenge.file_content
      })

      Letsencrypt.update_challenge(challenge.filename, challenge.file_content)

      attempt_heroku_challenge_filename_after_update = update_result['ACME_CHALLENGE_FILENAME']
      attempt_heroku_challenge_file_content_after_update = update_result['ACME_CHALLENGE_FILE_CONTENT']

      attempt_letsencrypt_config_filename_after_update = configuration.challenge_filename
      attempt_letsencrypt_config_file_content_after_update = configuration.challenge_file_content

      puts "Done!"

      # Wait for app to come up
      print "Testing filename works (to bring up app)...\n"

      # Get the domain name from Heroku
      hostname = heroku.domain.list(heroku_app).first['hostname']

      # Wait at least a little bit, otherwise the first request will almost always fail.
      sleep(2)

      start_time = Time.now

      print "!! Calling: http://#{hostname}/#{challenge.filename}\n"

      begin
        open("http://#{hostname}/#{challenge.filename}").read
      rescue OpenURI::HTTPError => e
        if Time.now - start_time <= 30
          puts "Error fetching challenge, retrying... #{e.message}"

          puts "******************************************************************\n"
          puts "Attempt #{attempt_number}: #{attempt_domain}  \n"
          puts "------------------------------------------------------------------\n"
          puts "Before Update, Letsencrypt Config, File Name: \n#{attempt_letsencrypt_config_filename_before_update} \n"
          puts "------------------------------------------------------------------\n"
          puts "Returned from ACME, File Name: \n#{attempt_challenge_filename_returned_from_acme} \n"
          puts "------------------------------------------------------------------\n"
          puts "After Update, Heroku Response, File Name: \n#{attempt_heroku_challenge_filename_after_update} \n"
          puts "After Update, Letsencrypt Config, File Name: \n#{attempt_letsencrypt_config_filename_after_update} \n"
          puts "******************************************************************\n\n\n"

          sleep(5)
          retry
        else
          puts "******************************************************************\n"
          puts "Attempt #{attempt_number}: #{attempt_domain}  \n"
          puts "------------------------------------------------------------------\n"
          puts "Before Update, Letsencrypt Config, File Name: \n#{attempt_letsencrypt_config_filename_before_update} \n"
          puts "------------------------------------------------------------------\n"
          puts "Returned from ACME, File Name: \n#{attempt_challenge_filename_returned_from_acme} \n"
          puts "------------------------------------------------------------------\n"
          puts "After Update, Heroku Response, File Name: \n#{attempt_heroku_challenge_filename_after_update} \n"
          puts "After Update, Letsencrypt Config, File Name: \n#{attempt_letsencrypt_config_filename_after_update} \n"
          puts "******************************************************************\n\n\n"

          failure_message = "Error waiting for response from http://#{hostname}/#{challenge.filename}, Error: #{e.message}"
          raise Letsencrypt::Error::ChallengeUrlError, failure_message
        end
      end

      puts "Done!"

      print "Giving LetsEncrypt some time to verify..."
      # Once you are ready to serve the confirmation request you can proceed.
      challenge.request_verification # => true
      challenge.verify_status # => 'pending'

      start_time = Time.now

      while challenge.verify_status == 'pending'
        if Time.now - start_time >= 30
          failure_message = "Failed - timed out waiting for challenge verification."
          raise Letsencrypt::Error::VerificationTimeoutError, failure_message
        end
        sleep(3)
      end

      puts "Done!"

      unless challenge.verify_status == 'valid'
        puts "Problem verifying challenge."
        failure_message = "Status: #{challenge.verify_status}, Error: #{challenge.error}"
        raise Letsencrypt::Error::VerificationError, failure_message
      end
    end

    # Unset temporary config vars. We don't care about waiting for this to
    # restart
    heroku.config_var.update(heroku_app, {
      'ACME_CHALLENGE_FILENAME' => nil,
      'ACME_CHALLENGE_FILE_CONTENT' => nil
    })

    # Create CSR
    csr = Acme::Client::CertificateRequest.new(names: domains)

    # Get certificate
    certificate = client.new_certificate(csr) # => #<Acme::Client::Certificate ....>

    # Send certificates to Heroku via API

    # First check for existing certificates:
    certificates = heroku.sni_endpoint.list(heroku_app)

    begin
      if certificates.any?
        print "Updating existing certificate #{certificates[0]['name']}..."
        heroku.sni_endpoint.update(heroku_app, certificates[0]['name'], {
          certificate_chain: certificate.fullchain_to_pem,
          private_key: certificate.request.private_key.to_pem
        })
        puts "Done!"
      else
        print "Adding new certificate..."
        heroku.sni_endpoint.create(heroku_app, {
          certificate_chain: certificate.fullchain_to_pem,
          private_key: certificate.request.private_key.to_pem
        })
        puts "Done!"
      end
    rescue Excon::Error::UnprocessableEntity => e
      warn "Error adding certificate to Heroku. Response from Heroku’s API follows:"
      raise Letsencrypt::Error::HerokuCertificateError, e.response.body
    end

  end

end
