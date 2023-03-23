module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class EbanxV2Gateway

      CARD_BRAND = {
        visa: 'visa',
        master: 'master_card',
        american_express: 'amex',
        discover: 'discover',
        diners_club: 'diners'
      }

      URL_MAP = {
        purchase: 'charge',
        authorize: 'charge',
        capture: 'capture',
        refund: 'refund',
        void: 'void',
        store: 'store'
      }

      HTTP_METHOD = {
        purchase: :post,
        authorize: :post,
        capture: :post,
        refund: :post,
        void: :post,
        store: :post
      }

      def initialize(integration_key)
        @integration_key = integration_key
        @test_url = 'https://sandbox.ebanxpay.com/channels/spreedly/'
        @live_url = 'https://api.ebanxpay.com/channels/spreedly/'
      end

      def purchase(amount, currency, payment, options = {})
        payload = {}
        payload[:options] = {}

        payload[:amount] = amount
        payload[:options] = options
        payload[:options][:currency] = currency

        add_card_or_token(payload, payment)
        payload
      end

      def authorize(amount, currency, payment, options = {})
        payload = {}
        payload[:options] = {}

        payload[:amount] = amount
        payload[:options] = options
        payload[:options][:currency] = currency

        add_card_or_token(payload, payment)

        payload[:creditcard][:auto_capture] = false

        payload
      end

      def capture(money, authorization, options = {})
        payload = {}
        payload[:authorization] = authorization
        payload[:amount] = money if options[:include_capture_amount].to_s == 'true'

        payload
      end

      def refund(money, authorization, options = {})
        payload = {}

        payload[:authorization] = authorization
        payload[:amount] = money
        payload[:description] = options[:description]

        payload
      end

      def void(authorization, options = {})
        payload = {}
        payload[:authorization] = authorization

        payload
      end

      def store(credit_card, options = {})
        payload = {}
        add_payment_details(payload, credit_card)
        payload[:country] = customer_country(options)

        payload
      end

      def url_for(is_test_env, action, parameters)
        hostname = is_test_env ? @test_url : @live_url
        "#{hostname}#{URL_MAP[action]}"
      end

      def post_data(action, parameters = {})
        "#{parameters.to_json}"
      end

      def get_http_method(action)
        HTTP_METHOD[action]
      end

      def headers(parameters)
        headers = { 'x-ebanx-client-user-agent': "ActiveMerchant/#{ActiveMerchant::VERSION}" }
        headers['authorization'] = @integration_key
        headers['content-type'] = "application/json"

        processing_type = parameters[:options][:processing_type] if parameters[:options].present? && parameters[:options][:processing_type].present?
        add_processing_type_to_headers(headers, processing_type) if processing_type && processing_type == 'local'

        headers
      end

      def authorization_from(action, parameters, response)
        if action == :store
          "#{response.try(:[], 'token')}|#{CARD_BRAND[parameters[:card][:brand].to_sym]}"
        else
          response.try(:[], 'payment').try(:[], 'hash')
        end
      end

      def customer_country(options)
        if country = options[:country] || (options[:billing_address][:country] if options[:billing_address])
          country.downcase
        end
      end

      private

      def add_processing_type_to_headers(commit_headers, processing_type)
        commit_headers['x-ebanx-api-processing-type'] = processing_type
      end

      def add_card_or_token(post, payment)
        post[:creditcard] = {}

        payment, brand = payment.split('|') if payment.is_a?(String)
        post[:creditcard] = payment_details(payment)
        post[:creditcard][:brand] = payment.is_a?(String) ? brand : payment.brand.to_sym
      end

      def add_payment_details(post, payment)
        post[:card] = payment_details(payment)
        post[:card][:brand] = payment.brand.to_sym
      end

      def payment_details(payment)
        if payment.is_a?(String)
          { token: payment }
        else
          {
            number: payment.number,
            first_name: payment.first_name,
            last_name: payment.last_name,
            month: payment.month,
            year: payment.year,
            verification_value: payment.verification_value
          }
        end
      end
    end
  end
end