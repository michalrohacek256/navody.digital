require 'omniauth'

module OmniAuth
  module Strategies
    class MagicLink
      include OmniAuth::Strategy

      option :fields, [:email]
      option :uid_field, :email
      option :on_send_link, nil
      option :info_path, nil
      option :code_lifetime, 10.minutes

      def request_phase
        email = request[:email]
        token = generate_magic_code(email, session.id)

        options[:on_send_link]&.call(email, token)

        redirect info_url + '?email=' + email
      end

      def callback_phase
        raw_info
        super
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        fail!(:invalid_credentials)
      end

      uid do
        raw_info[:email]
      end

      info do
        raw_info
      end

      def raw_info
        @raw_info ||= begin
          token = request[:token]
          payload = verifier.verify(token, purpose: :magic_link).symbolize_keys
          fail!(:invalid_credentials) if payload[:session_id] != session.id
          payload
        end
      end

      protected

      def generate_magic_code(email, session_id)
        verifier
          .generate(
            verifier_payload(email, session_id),
            expires_in: options[:code_lifetime],
            purpose: :magic_link
          )
      end

      def info_path
        options[:info_path] || "#{path_prefix}/#{name}/info"
      end

      def info_url
        full_host + script_name + info_path
      end

      def secret_key
        Rails.application.config.secret_key_base || 'secret'
      end

      def verifier_payload(email, session_id)
        { email: email, session_id: session_id }
      end

      def verifier
        ActiveSupport::MessageVerifier.new(secret_key)
      end
    end
  end
end
