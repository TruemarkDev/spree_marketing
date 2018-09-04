module Spree
  module Marketing
    class List
      class FavourableProducts < Spree::Marketing::List
        include Spree::Marketing::ActsAsMultiList

        # Constants
        NAME_TEXT = 'Most Selling Products'
        ENTITY_KEY = 'entity_id'
        ENTITY_TYPE = 'Spree::Product'
        TIME_FRAME = 1.month
        FAVOURABLE_PRODUCT_COUNT = 10
        AVAILABLE_REPORTS = %i[cart_additions_by purchases_by product_views_by].freeze

        def user_ids
          # FIXME: There might be a case where a guest user have placed an order
          # And we also have his email but we are leaving those emails for now.
          Spree::Order.joins(line_items: { variant: :product })
                      .of_registered_users
                      .where('spree_orders.completed_at >= :time_frame', time_frame: computed_time)
                      .where('spree_products.id = ?', entity_id)
                      .group(:user_id)
                      .pluck(:user_id)
        end

        def self.data
          Spree::Order.joins(line_items: { variant: :product })
                      .where('spree_orders.completed_at >= :time_frame', time_frame: computed_time)
                      .group('spree_products.id')
                      .order(Arel.sql("COUNT(spree_orders.id) DESC"))
                      .limit(FAVOURABLE_PRODUCT_COUNT)
                      .pluck('spree_products.id')
        end
        private_class_method :data
      end
    end
  end
end
