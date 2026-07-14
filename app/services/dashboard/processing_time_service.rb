module Dashboard
  class ProcessingTimeService
    # Routine TAT target in minutes (sla)
    TARGET_MINUTES = 61

    # Bucket cutoffs in minutes: [0, 30), [30, 60), [60, +inf)
    BUCKET_CUTOFFS = [ 30, 60 ].freeze

    # Category shown when an examination has no category assigned.
    UNCATEGORIZED_LABEL = "Lainnya"

    def self.call(start_date:, end_date:)
      new(start_date: start_date, end_date: end_date).call
    end

    def initialize(start_date:, end_date:)
      @start_date = start_date
      @end_date   = end_date
    end

    def call
      pending_works = Work
        .joins(:examination)
        .where(status: Work.statuses[:pending])
        .where("works.created_at >= ?", start_date.beginning_of_day)
        .where("works.created_at <= ?", end_date.end_of_day)
        .pluck(:created_at, "examinations.category")

      now = Time.current
      buckets = bucket_pending_works(pending_works, now)

      avg_tat_seconds = Work
        .where(status: Work.statuses[:verified])
        .where.not(verified_at: nil)
        .where("works.created_at >= ?", start_date.beginning_of_day)
        .where("works.created_at <= ?", end_date.end_of_day)
        .pick(Arel.sql("AVG(EXTRACT(EPOCH FROM (works.verified_at - works.created_at)))"))

      under_60_count = Work
        .where(status: Work.statuses[:verified])
        .where.not(verified_at: nil)
        .where("works.created_at >= ?", start_date.beginning_of_day)
        .where("works.created_at <= ?", end_date.end_of_day)
        .where("works.verified_at - works.created_at < interval '60 minutes'")
        .count

      total_verified = Work
        .where(status: Work.statuses[:verified])
        .where.not(verified_at: nil)
        .where("works.created_at >= ?", start_date.beginning_of_day)
        .where("works.created_at <= ?", end_date.end_of_day)
        .count

      ServiceResult.success(
        chart: {
          labels: buckets[:labels],
          series: {
            lt_30:  buckets[:lt_30],
            mid:    buckets[:mid],
            gt_60:  buckets[:gt_60]
          }
        },
        stats: {
          avg_tat_minutes: avg_tat_seconds ? (avg_tat_seconds / 60.0).round : nil,
          pct_under_60:    total_verified.positive? ? ((under_60_count.to_f / total_verified) * 100).round : nil,
          target_minutes:  TARGET_MINUTES,
          verified_count:  total_verified
        }
      ).to_h
    end

    private

    attr_reader :start_date, :end_date

    # pending_works: Array<[created_at_time, category_or_nil]>
    # Returns: { labels: [...], lt_30: [...], mid: [...], gt_60: [...] }
    def bucket_pending_works(pending_works, now)
      grouped = Hash.new { |h, k| h[k] = [ 0, 0, 0 ] }

      pending_works.each do |created_at, category|
        age_min = ((now - created_at) / 60.0).round
        label   = category.presence || UNCATEGORIZED_LABEL
        index   = bucket_index(age_min)
        grouped[label][index] += 1
      end

      sorted_labels = grouped.keys.sort
      {
        labels: sorted_labels,
        lt_30:  sorted_labels.map { |l| grouped[l][0] },
        mid:    sorted_labels.map { |l| grouped[l][1] },
        gt_60:  sorted_labels.map { |l| grouped[l][2] }
      }
    end

    # 0 = [0, 30), 1 = [30, 60), 2 = [60, +inf)
    def bucket_index(age_min)
      BUCKET_CUTOFFS.each_with_index do |cutoff, idx|
        return idx if age_min < cutoff
      end
      BUCKET_CUTOFFS.length
    end
  end
end
