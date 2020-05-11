module Search
  module QueryBuilders
    class ChatChannelMembership < QueryBase
      FILTER_KEYS = %i[
        channel_status
        channel_type
        status
        viewable_by
      ].freeze

      QUERY_KEYS = %i[
        channel_text
      ].freeze

      DEFAULT_PARAMS = {
        sort_by: "channel_last_message_at",
        sort_direction: "desc",
        size: 0
      }.freeze

      def initialize(params:)
        @params = params.deep_symbolize_keys
        @params[:viewable_by] = @params[:user_id]

        # TODO: @mstruve: When we want to allow people like admins to
        # search ALL memberships this will need to change
        @params[:status] = %w[active joining_request]

        build_body
      end

      private

      def build_queries
        @body[:query] = {}
        @body[:query][:bool] = { filter: filter_conditions }
        @body[:query][:bool][:must] = query_conditions if query_keys_present?
      end

      def filter_conditions
        FILTER_KEYS.map do |filter_key|
          next if @params[filter_key].blank? || @params[filter_key] == "all"

          if %i[viewable_by status].include? filter_key
            { terms: { filter_key => @params[filter_key] } }
          else
            { term: { filter_key => @params[filter_key] } }
          end
        end.compact
      end
    end
  end
end
