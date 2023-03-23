require 'test_helper'

class RemoteEbanxTest < Test::Unit::TestCase
  def setup
    @amount = 100
    @credit_card = credit_card('4111111111111111')
    @declined_card = credit_card('5102026827345142')
    @options = {
      billing_address: address({
                                 address1: '1040 Rua E',
                                 city: 'Maracanaú',
                                 state: 'CE',
                                 zip: '61919-230',
                                 country: 'BR',
                                 phone_number: '8522847035'
                               }),
      order_id: generate_unique_id,
      document: '853.513.468-93',
      device_id: '34c376b2767',
      metadata: {
        metadata_1: 'test',
        metadata_2: 'test2'
      },
      tags: EbanxGateway::TAGS,
      soft_descriptor: 'ActiveMerchant'
    }
  end

  [
    [:ebanx, 'v1'],
    [:ebanx_v2, 'v2'],
  ].each do |integration_key, version|
    test "expecting successful purchase for #{version}" do
      @gateway = EbanxGateway.new(fixtures(integration_key))
      response = @gateway.purchase(@amount, @credit_card, @options)
      assert_success response
      assert_equal 'Accepted', response.message
    end
  end

  [
    [:ebanx, 'v1'],
    [:ebanx_v2, 'v2'],
  ].each do |integration_key, version|
    test "expecting successful purchase with more options for #{version}" do
      @gateway = EbanxGateway.new(fixtures(integration_key))
      options = @options.merge({
                                 order_id: generate_unique_id,
                                 ip: '127.0.0.1',
                                 email: 'joe@example.com',
                                 birth_date: '10/11/1980',
                                 person_type: 'personal'
                               })
      response = @gateway.purchase(@amount, @credit_card, options)
      assert_success response
      assert_equal 'Accepted', response.message
    end
  end

  [
    [:ebanx, 'v1'],
    [:ebanx_v2, 'v2'],
  ].each do |integration_key, version|
    test "successful purchase passing processing type in header for #{version}" do
      @gateway = EbanxGateway.new(fixtures(integration_key))
      @options.merge({ processing_type: 'local' })
      @options.merge({ integration_key: 'test_ik_rFzG7hylTozF9EgaUnC_Bg' })
      response = @gateway.purchase(@amount, @credit_card, @options)

      assert_success response
      assert_equal 'Accepted', response.message
    end
  end

  [
    [:ebanx, 'v1'],
    [:ebanx_v2, 'v2'],
  ].each do |integration_key, version|
    test "successful purchase as brazil business with responsible fields for #{version}" do
      @gateway = EbanxGateway.new(fixtures(integration_key))
      options = @options.update(document: '32593371000110',
                                person_type: 'business',
                                responsible_name: 'Business Person',
                                responsible_document: '32593371000111',
                                responsible_birth_date: '1/11/1975')

      response = @gateway.purchase(@amount, @credit_card, options)
      assert_success response
      assert_equal 'Accepted', response.message
    end
  end

  [
    [:ebanx, 'v1'],
    [:ebanx_v2, 'v2'],
  ].each do |integration_key, version|
    test "successful purchase as colombian for #{version}" do
      @gateway = EbanxGateway.new(fixtures(integration_key))
      options = @options.merge({
                                 order_id: generate_unique_id,
                                 ip: '127.0.0.1',
                                 email: 'jose@example.com.co',
                                 birth_date: '10/11/1980',
                                 billing_address: address({
                                                            address1: '1040 Rua E',
                                                            city: 'Medellín',
                                                            state: 'AN',
                                                            zip: '29269',
                                                            country: 'CO',
                                                            phone_number: '8522847035'
                                                          })
                               })

      response = @gateway.purchase(500, @credit_card, options)
      assert_success response
      assert_equal 'Accepted', response.message
    end
  end

  [
    [:ebanx, 'v1'],
    [:ebanx_v2, 'v2'],
  ].each do |integration_key, version|
    test "failed purchase for #{version}" do
      @gateway = EbanxGateway.new(fixtures(integration_key))
      response = @gateway.purchase(@amount, @declined_card, @options)
      assert_failure response
      assert_equal 'Invalid card or card type', response.message
      assert_equal 'NOK', response.error_code
    end
  end

  [
    [:ebanx, 'v1'],
    [:ebanx_v2, 'v2'],
  ].each do |integration_key, version|
    test "successful authorize and capture for #{version}" do
      @gateway = EbanxGateway.new(fixtures(integration_key))
      auth = @gateway.authorize(@amount, @credit_card, @options)
      assert_success auth
      assert_equal 'Accepted', auth.message

      assert capture = @gateway.capture(@amount, auth.authorization, @options)
      assert_success capture
      assert_equal 'Accepted', capture.message
    end
  end

  [
    [:ebanx, 'v1'],
    [:ebanx_v2, 'v2'],
  ].each do |integration_key, version|
    test "failed authorize for #{version}" do
      @gateway = EbanxGateway.new(fixtures(integration_key))
      response = @gateway.authorize(@amount, @declined_card, @options)
      assert_failure response
      assert_equal 'Invalid card or card type', response.message
      assert_equal 'NOK', response.error_code
    end
  end

  [
    [:ebanx, 'v1'],
    [:ebanx_v2, 'v2'],
  ].each do |integration_key, version|
    test "successful partial capture when include capture amount is not passed for #{version}" do
      @gateway = EbanxGateway.new(fixtures(integration_key))
      auth = @gateway.authorize(@amount, @credit_card, @options)
      assert_success auth

      assert capture = @gateway.capture(@amount - 1, auth.authorization)
      assert_success capture
    end
  end

  [
    [:ebanx, 'v1'],
    [:ebanx_v2, 'v2'],
  ].each do |integration_key, version|
    # Partial capture is only available in Brazil and the EBANX Integration Team must be contacted to enable
    test "failed partial capture when include capture amount is passed for #{version}" do
      @gateway = EbanxGateway.new(fixtures(integration_key))
      auth = @gateway.authorize(@amount, @credit_card, @options)
      assert_success auth

      assert capture = @gateway.capture(@amount - 1, auth.authorization, @options.merge(include_capture_amount: true))
      assert_failure capture
      assert_equal 'Partial capture not available', capture.message
    end
  end

  [
    [:ebanx, 'v1'],
    [:ebanx_v2, 'v2'],
  ].each do |integration_key, version|
    test "failedcapture for #{version}" do
      @gateway = EbanxGateway.new(fixtures(integration_key))
      response = @gateway.capture(@amount, '')
      assert_failure response
      assert_equal 'Parameters hash or merchant_payment_code not informed', response.message
    end
  end

  [
    [:ebanx, 'v1'],
    [:ebanx_v2, 'v2'],
  ].each do |integration_key, version|
    test "successful refund for #{version}" do
      @gateway = EbanxGateway.new(fixtures(integration_key))
      purchase = @gateway.purchase(@amount, @credit_card, @options)
      assert_success purchase

      refund_options = @options.merge({ description: 'full refund' })
      assert refund = @gateway.refund(@amount, purchase.authorization, refund_options)
      assert_success refund
      assert_equal 'Accepted', refund.message
    end
  end

  [
    [:ebanx, 'v1'],
    [:ebanx_v2, 'v2'],
  ].each do |integration_key, version|
    test "partial refund for #{version}" do
      @gateway = EbanxGateway.new(fixtures(integration_key))
      purchase = @gateway.purchase(@amount, @credit_card, @options)
      assert_success purchase

      refund_options = @options.merge(description: 'refund due to returned item')
      assert refund = @gateway.refund(@amount - 1, purchase.authorization, refund_options)
      assert_success refund
    end
  end

  [
    [:ebanx, 'v1'],
    [:ebanx_v2, 'v2'],
  ].each do |integration_key, version|
    test "failed refund for #{version}" do
      @gateway = EbanxGateway.new(fixtures(integration_key))
      response = @gateway.refund(@amount, '')
      assert_failure response
      assert_match('Parameter hash not informed', response.message)
    end
  end

  [
    [:ebanx, 'v1'],
    [:ebanx_v2, 'v2'],
  ].each do |integration_key, version|
    test "successful void for #{version}" do
      @gateway = EbanxGateway.new(fixtures(integration_key))
      auth = @gateway.authorize(@amount, @credit_card, @options)
      assert_success auth

      assert void = @gateway.void(auth.authorization)
      assert_success void
      assert_equal 'Accepted', void.message
    end
  end
  require 'test_helper'

  class RemoteEbanxTest < Test::Unit::TestCase
    def setup
      @amount = 100
      @credit_card = credit_card('4111111111111111')
      @declined_card = credit_card('5102026827345142')
      @options = {
        billing_address: address({
                                   address1: '1040 Rua E',
                                   city: 'Maracanaú',
                                   state: 'CE',
                                   zip: '61919-230',
                                   country: 'BR',
                                   phone_number: '8522847035'
                                 }),
        order_id: generate_unique_id,
        document: '853.513.468-93',
        device_id: '34c376b2767',
        metadata: {
          metadata_1: 'test',
          metadata_2: 'test2'
        },
        tags: EbanxGateway::TAGS,
        soft_descriptor: 'ActiveMerchant'
      }
    end

    [
      [:ebanx, 'v1'],
      [:ebanx_v2, 'v2'],
    ].each do |integration_key, version|
      test "expecting successful purchase for #{version}" do
        @gateway = EbanxGateway.new(fixtures(integration_key))
        response = @gateway.purchase(@amount, @credit_card, @options)
        assert_success response
        assert_equal 'Accepted', response.message
      end
    end

    [
      [:ebanx, 'v1'],
      [:ebanx_v2, 'v2'],
    ].each do |integration_key, version|
      test "expecting successful purchase with more options for #{version}" do
        @gateway = EbanxGateway.new(fixtures(integration_key))
        options = @options.merge({
                                   order_id: generate_unique_id,
                                   ip: '127.0.0.1',
                                   email: 'joe@example.com',
                                   birth_date: '10/11/1980',
                                   person_type: 'personal'
                                 })
        response = @gateway.purchase(@amount, @credit_card, options)
        assert_success response
        assert_equal 'Accepted', response.message
      end
    end

    [
      [:ebanx, 'v1'],
      [:ebanx_v2, 'v2'],
    ].each do |integration_key, version|
      test "successful purchase passing processing type in header for #{version}" do
        @gateway = EbanxGateway.new(fixtures(integration_key))
        @options.merge({ processing_type: 'local' })
        @options.merge({ integration_key: 'test_ik_rFzG7hylTozF9EgaUnC_Bg' })
        response = @gateway.purchase(@amount, @credit_card, @options)

        assert_success response
        assert_equal 'Accepted', response.message
      end
    end

    [
      [:ebanx, 'v1'],
      [:ebanx_v2, 'v2'],
    ].each do |integration_key, version|
      test "successful purchase as brazil business with responsible fields for #{version}" do
        @gateway = EbanxGateway.new(fixtures(integration_key))
        options = @options.update(document: '32593371000110',
                                  person_type: 'business',
                                  responsible_name: 'Business Person',
                                  responsible_document: '32593371000111',
                                  responsible_birth_date: '1/11/1975')

        response = @gateway.purchase(@amount, @credit_card, options)
        assert_success response
        assert_equal 'Accepted', response.message
      end
    end

    [
      [:ebanx, 'v1'],
      [:ebanx_v2, 'v2'],
    ].each do |integration_key, version|
      test "successful purchase as colombian for #{version}" do
        @gateway = EbanxGateway.new(fixtures(integration_key))
        options = @options.merge({
                                   order_id: generate_unique_id,
                                   ip: '127.0.0.1',
                                   email: 'jose@example.com.co',
                                   birth_date: '10/11/1980',
                                   billing_address: address({
                                                              address1: '1040 Rua E',
                                                              city: 'Medellín',
                                                              state: 'AN',
                                                              zip: '29269',
                                                              country: 'CO',
                                                              phone_number: '8522847035'
                                                            })
                                 })

        response = @gateway.purchase(500, @credit_card, options)
        assert_success response
        assert_equal 'Accepted', response.message
      end
    end

    [
      [:ebanx, 'v1'],
      [:ebanx_v2, 'v2'],
    ].each do |integration_key, version|
      test "failed purchase for #{version}" do
        @gateway = EbanxGateway.new(fixtures(integration_key))
        response = @gateway.purchase(@amount, @declined_card, @options)
        assert_failure response
        assert_equal 'Invalid card or card type', response.message
        assert_equal 'NOK', response.error_code
      end
    end

    [
      [:ebanx, 'v1'],
      [:ebanx_v2, 'v2'],
    ].each do |integration_key, version|
      test "successful authorize and capture for #{version}" do
        @gateway = EbanxGateway.new(fixtures(integration_key))
        auth = @gateway.authorize(@amount, @credit_card, @options)
        assert_success auth
        assert_equal 'Accepted', auth.message

        assert capture = @gateway.capture(@amount, auth.authorization, @options)
        assert_success capture
        assert_equal 'Accepted', capture.message
      end
    end

    [
      [:ebanx, 'v1'],
      [:ebanx_v2, 'v2'],
    ].each do |integration_key, version|
      test "failed authorize for #{version}" do
        @gateway = EbanxGateway.new(fixtures(integration_key))
        response = @gateway.authorize(@amount, @declined_card, @options)
        assert_failure response
        assert_equal 'Invalid card or card type', response.message
        assert_equal 'NOK', response.error_code
      end
    end

    [
      [:ebanx, 'v1'],
      [:ebanx_v2, 'v2'],
    ].each do |integration_key, version|
      test "successful partial capture when include capture amount is not passed for #{version}" do
        @gateway = EbanxGateway.new(fixtures(integration_key))
        auth = @gateway.authorize(@amount, @credit_card, @options)
        assert_success auth

        assert capture = @gateway.capture(@amount - 1, auth.authorization)
        assert_success capture
      end
    end

    [
      [:ebanx, 'v1'],
      [:ebanx_v2, 'v2'],
    ].each do |integration_key, version|
      # Partial capture is only available in Brazil and the EBANX Integration Team must be contacted to enable
      test "failed partial capture when include capture amount is passed for #{version}" do
        @gateway = EbanxGateway.new(fixtures(integration_key))
        auth = @gateway.authorize(@amount, @credit_card, @options)
        assert_success auth

        assert capture = @gateway.capture(@amount - 1, auth.authorization, @options.merge(include_capture_amount: true))
        assert_failure capture
        assert_equal 'Partial capture not available', capture.message
      end
    end

    [
      [:ebanx, 'v1'],
      [:ebanx_v2, 'v2'],
    ].each do |integration_key, version|
      test "failedcapture for #{version}" do
        @gateway = EbanxGateway.new(fixtures(integration_key))
        response = @gateway.capture(@amount, '')
        assert_failure response
        assert_equal 'Parameters hash or merchant_payment_code not informed', response.message
      end
    end

    [
      [:ebanx, 'v1'],
      [:ebanx_v2, 'v2'],
    ].each do |integration_key, version|
      test "successful refund for #{version}" do
        @gateway = EbanxGateway.new(fixtures(integration_key))
        purchase = @gateway.purchase(@amount, @credit_card, @options)
        assert_success purchase

        refund_options = @options.merge({ description: 'full refund' })
        assert refund = @gateway.refund(@amount, purchase.authorization, refund_options)
        assert_success refund
        assert_equal 'Accepted', refund.message
      end
    end

    [
      [:ebanx, 'v1'],
      [:ebanx_v2, 'v2'],
    ].each do |integration_key, version|
      test "partial refund for #{version}" do
        @gateway = EbanxGateway.new(fixtures(integration_key))
        purchase = @gateway.purchase(@amount, @credit_card, @options)
        assert_success purchase

        refund_options = @options.merge(description: 'refund due to returned item')
        assert refund = @gateway.refund(@amount - 1, purchase.authorization, refund_options)
        assert_success refund
      end
    end

    [
      [:ebanx, 'v1'],
      [:ebanx_v2, 'v2'],
    ].each do |integration_key, version|
      test "failed refund for #{version}" do
        @gateway = EbanxGateway.new(fixtures(integration_key))
        response = @gateway.refund(@amount, '')
        assert_failure response
        assert_match('Parameter hash not informed', response.message)
      end
    end

    [
      [:ebanx, 'v1'],
      [:ebanx_v2, 'v2'],
    ].each do |integration_key, version|
      test "successful void for #{version}" do
        @gateway = EbanxGateway.new(fixtures(integration_key))
        auth = @gateway.authorize(@amount, @credit_card, @options)
        assert_success auth

        assert void = @gateway.void(auth.authorization)
        assert_success void
        assert_equal 'Accepted', void.message
      end
    end
  end
end