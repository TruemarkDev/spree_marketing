require 'spec_helper'

describe Spree::Marketing::List::MostUsedPaymentMethods, type: :model do
  let(:payment_method) { create(:credit_card_payment_method) }
  let(:entity_id) { payment_method.id }
  let(:entity_name) { payment_method.name }
  let!(:user_with_more_than_5_completed_orders) { create(:user_with_completed_orders, :with_given_payment_method, payment_method: payment_method, orders_count: 6) }

  it_behaves_like 'acts_as_multilist', Spree::Marketing::List::MostUsedPaymentMethods

  describe 'Constants' do
    it 'NAME_TEXT equals to name representation for list' do
      expect(Spree::Marketing::List::MostUsedPaymentMethods::NAME_TEXT).to eq 'Most Used Payment Methods'
    end
    it 'ENTITY_KEY equals to entity attribute for list' do
      expect(Spree::Marketing::List::MostUsedPaymentMethods::ENTITY_KEY).to eq 'entity_id'
    end
    it 'ENTITY_TYPE equals to type of entity for list' do
      expect(Spree::Marketing::List::MostUsedPaymentMethods::ENTITY_TYPE).to eq 'Spree::PaymentMethod'
    end
    it 'TIME_FRAME equals to time frame used in filtering of users for list' do
      expect(Spree::Marketing::List::MostUsedPaymentMethods::TIME_FRAME).to eq 1.month
    end
    it 'MOST_USED_PAYMENT_METHODS_COUNT equals to count of payment methods to be used for data for lists' do
      expect(Spree::Marketing::List::MostUsedPaymentMethods::MOST_USED_PAYMENT_METHODS_COUNT).to eq 5
    end
    it 'MINIMUM_COUNT equals to minimum count of orders made by users for a payment method for list' do
      expect(Spree::Marketing::List::MostUsedPaymentMethods::MINIMUM_COUNT).to eq 5
    end
    it 'AVAILABLE_REPORTS equals to array of reports for this list type' do
      expect(Spree::Marketing::List::MostUsedPaymentMethods::AVAILABLE_REPORTS).to eq [:purchases_by]
    end
  end

  describe 'methods' do
    describe '#user_ids' do
      context 'with users having greater than 5 orders' do
        let!(:user_with_less_than_5_completed_orders) { create(:user_with_completed_orders, :with_given_payment_method, orders_count: 4, payment_method: payment_method) }

        it { expect(Spree::Marketing::List::MostUsedPaymentMethods.new(entity_id: payment_method.id, entity_type: 'Spree::PaymentMethod').user_ids).to include user_with_more_than_5_completed_orders.id }
        it { expect(Spree::Marketing::List::MostUsedPaymentMethods.new(entity_id: payment_method.id, entity_type: 'Spree::PaymentMethod').user_ids).to_not include user_with_less_than_5_completed_orders.id }
      end

      context 'with users having greater than 5 orders orders with selected payment method' do
        let(:other_payment_method) { create(:check_payment_method) }
        let!(:user_with_more_than_5_completed_orders_with_other_payment_method) { create(:user_with_completed_orders, :with_given_payment_method, orders_count: 6, payment_method: other_payment_method) }

        it { expect(Spree::Marketing::List::MostUsedPaymentMethods.new(entity_id: payment_method.id, entity_type: 'Spree::PaymentMethod').user_ids).to include user_with_more_than_5_completed_orders.id }
        it { expect(Spree::Marketing::List::MostUsedPaymentMethods.new(entity_id: payment_method.id, entity_type: 'Spree::PaymentMethod').user_ids).to_not include user_with_more_than_5_completed_orders_with_other_payment_method.id }
      end

      context 'with users having greater than 5 orders completed before TIME_FRAME' do
        let(:timestamp) { Time.current - 2.months }
        let(:user_having_more_than_5_old_completed_orders) { create(:user_with_completed_orders, :with_given_payment_method, :with_custom_completed_at, completed_at: timestamp, orders_count: 6, payment_method: payment_method) }

        it { expect(Spree::Marketing::List::MostUsedPaymentMethods.new(entity_id: payment_method.id, entity_type: 'Spree::PaymentMethod').user_ids).to include user_with_more_than_5_completed_orders.id }
        it { expect(Spree::Marketing::List::MostUsedPaymentMethods.new(entity_id: payment_method.id, entity_type: 'Spree::PaymentMethod').user_ids).to_not include user_having_more_than_5_old_completed_orders.id }
      end

      context 'when user is not registered having greater than 5 orders' do
        let(:guest_user_email) { 'spree@example.com' }
        let!(:guest_user_having_more_than_5_completed_order_with_given_payment_method) { create_list(:guest_user_order_with_given_payment_method, 6, email: guest_user_email, payment_method: payment_method) }

        it { expect(Spree::Marketing::List::MostUsedPaymentMethods.new(entity_id: payment_method.id, entity_type: 'Spree::PaymentMethod').send(:users_data).keys).to_not include guest_user_email }
      end
    end

    describe  '.data' do
      context 'with completed orders having completed payment' do
        let(:other_payment_method) { create(:check_payment_method) }
        let!(:order_with_incomplete_payment) { create(:order_with_given_payment_method, :incomplete_payment, payment_method: other_payment_method) }

        it { expect(Spree::Marketing::List::MostUsedPaymentMethods.send(:data)).to include payment_method.id }
        it { expect(Spree::Marketing::List::MostUsedPaymentMethods.send(:data)).to_not include other_payment_method.id }
      end

      context 'limit to MOST_USED_PAYMENT_METHODS_COUNT' do
        let(:second_payment_method) { create(:credit_card_payment_method) }
        let(:third_payment_method) { create(:credit_card_payment_method) }
        let(:fourth_payment_method) { create(:credit_card_payment_method) }
        let(:fifth_payment_method) { create(:credit_card_payment_method) }
        let(:sixth_payment_method) { create(:credit_card_payment_method) }
        let!(:completed_orders_with_second_payment_method) { create_list(:order_with_given_payment_method, 6, payment_method: second_payment_method) }
        let!(:completed_orders_with_third_payment_method) { create_list(:order_with_given_payment_method, 6, payment_method: third_payment_method) }
        let!(:completed_orders_with_fourth_payment_method) { create_list(:order_with_given_payment_method, 6, payment_method: fourth_payment_method) }
        let!(:completed_orders_with_fifth_payment_method) { create_list(:order_with_given_payment_method, 6, payment_method: fifth_payment_method) }
        let!(:completed_orders_with_sixth_payment_method) { create_list(:order_with_given_payment_method, 1, payment_method: sixth_payment_method) }

        it { expect(Spree::Marketing::List::MostUsedPaymentMethods.send(:data)).to include payment_method.id }
        it { expect(Spree::Marketing::List::MostUsedPaymentMethods.send(:data)).to include second_payment_method.id }
        it { expect(Spree::Marketing::List::MostUsedPaymentMethods.send(:data)).to include third_payment_method.id }
        it { expect(Spree::Marketing::List::MostUsedPaymentMethods.send(:data)).to include fourth_payment_method.id }
        it { expect(Spree::Marketing::List::MostUsedPaymentMethods.send(:data)).to include fifth_payment_method.id }
        it { expect(Spree::Marketing::List::MostUsedPaymentMethods.send(:data)).to_not include sixth_payment_method.id }
      end
    end

    context 'with payment methods having old orders' do
      let(:other_payment_method) { create(:credit_card_payment_method) }
      let(:timestamp) { Time.current - 1.month }
      let!(:other_payment_method_old_completed_orders) { create_list(:order_with_given_payment_method, 6, :with_custom_completed_at, payment_method: other_payment_method, completed_at: timestamp) }

      it 'returns payment method ids which will not include payment methods having orders only before time frame' do
        expect(Spree::Marketing::List::MostUsedPaymentMethods.send(:data)).to_not include other_payment_method.id
      end
    end
  end
end
