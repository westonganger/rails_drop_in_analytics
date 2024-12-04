module RailsLocalAnalytics
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true

    scope :multi_search, ->(full_str){
      if full_str.present?
        relation = self

        full_str.split(' ').each do |str|
          like = connection.adapter_name.downcase.to_s == "postgres" ? "ILIKE" : "LIKE"

          sql_conditions = []

          display_columns.each do |col|
            sql_conditions << "(#{col} #{like} :search)"
          end

          relation = relation.where(sql_conditions.join(" OR "), search: "%#{sanitize_sql_like(str)}%")
        end

        next relation
      end
    }

    def self.display_columns
      column_names - ["id", "created_at", "updated_at", "total", "day"]
    end

  end
end
