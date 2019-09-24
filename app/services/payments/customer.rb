module Payments
  # A thin wrapper on Stripe Customers and Charges APIs
  # see: <https://stripe.com/docs/api/customers/object>,
  # <https://stripe.com/docs/api/charges>
  class Customer
    class << self
      def get(customer_id)
        request do
          Stripe::Customer.retrieve(customer_id)
        end
      end

      def create(**params)
        request do
          Stripe::Customer.create(**params)
        end
      end

      def create_source(customer_id, token)
        request do
          Stripe::Customer.create_source(customer_id, source: token)
        end
      end

      def get_source(customer, source_id)
        request do
          customer.sources.retrieve(source_id)
        end
      end

      def charge(customer:, amount:, description:, card_id: nil)
        source = card_id || customer.default_source

        request do
          Stripe::Charge.create(
            customer: customer.id,
            source: source,
            amount: amount,
            description: description,
            currency: "usd",
          )
        end
      end

      def request
        yield
      rescue Stripe::InvalidRequestError => e
        raise InvalidRequestError, e.message
      rescue Stripe::CardError => e
        raise CardError, e.message
      rescue Stripe::StripeError => e
        Rails.logger.error(e)
        raise PaymentsError, e.message
      end
    end
  end
end
