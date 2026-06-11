module Specimens
  class OrderNumberGenerator
    MAX_DAILY_SEQUENCE = 9_999

    class DailySequenceExhausted < StandardError; end

    def self.call(date: Time.current.to_date)
      new(date: date).call
    end

    def initialize(date:)
      @date = date
    end

    def call
      sequence_value = next_sequence_value
      raise DailySequenceExhausted, "Daily specimen sequence is exhausted for #{date.iso8601}" unless sequence_value

      "#{date.strftime('%y%m%d')}#{format('%04d', sequence_value.to_i)}"
    end

    private

    attr_reader :date

    def next_sequence_value
      connection.select_value(<<~SQL.squish)
        INSERT INTO daily_sequences (sequence_date, last_value, created_at, updated_at)
        VALUES (#{connection.quote(date)}, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        ON CONFLICT (sequence_date) DO UPDATE
        SET last_value = daily_sequences.last_value + 1,
            updated_at = CURRENT_TIMESTAMP
        WHERE daily_sequences.last_value < #{MAX_DAILY_SEQUENCE}
        RETURNING last_value
      SQL
    end

    def connection
      ApplicationRecord.connection
    end
  end
end
