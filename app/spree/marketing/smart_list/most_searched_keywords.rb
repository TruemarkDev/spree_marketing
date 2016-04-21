module Spree
  module Marketing
    module SmartList
      class MostSearchedKeyword < Base

        TIME_FRAME = 1.month

        def initialize searched_keyword, list_uid = nil
          @searched_keyword = searched_keyword
          super(TIME_FRAME, list_uid)
        end

        def query
          Spree::PageEvent.includes(:actor)
                          .where(search_keywords: @searched_keyword)
                          .where("created_at >= :time_frame", time_frame: computed_time_frame)
                          .where.not(actor_id: nil)
                          .where(actor_type: Spree.user_class)
                          .group(:actor_id)
                          .having("COUNT(spree_page_events.id) > ?", 5)
                          .map { |page_event| page_event.actor }
        end

        def self.process
          Reports::MostSearchedKeyword.new.query.each do |keyword|

          end
        end
      end
    end
  end
end
