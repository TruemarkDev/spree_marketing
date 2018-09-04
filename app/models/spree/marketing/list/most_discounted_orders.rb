module Spree
  module Marketing
    class List
      class MostDiscountedOrders < Spree::Marketing::List
        # Constants
        NAME_TEXT = 'Discount Seekers'
        TIME_FRAME = 1.month
        MINIMUM_COUNT = 5
        AVAILABLE_REPORTS = %i[cart_additions_by purchases_by product_views_by].freeze

        def user_ids
          # FIXME: there is a case where guest user email is available but we are leaving that now.
          Spree::Order.joins(:promotions)
                      .where('spree_orders.completed_at >= :time_frame', time_frame: computed_time)
                      .group(:user_id)
                      .having('COUNT(spree_orders.id) > :minimum_count', minimum_count: MINIMUM_COUNT)
                      .of_registered_users
                      .order(Arel.sql("COUNT(spree_orders.id) DESC"))
                      .pluck(:user_id)
        end
      end
    end
  end
end
