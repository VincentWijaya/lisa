class DashboardController < ApplicationController
  before_action :authenticate_user!

  STATS_CACHE_KEY = "dashboard/stats"
  STATS_TTL = 2.minutes

  def index
    @start_date, @end_date = parse_range(params[:start_date], params[:end_date])

    stats = Rails.cache.fetch(cache_key_for(@start_date, @end_date), expires_in: STATS_TTL) do
      build_stats(@start_date, @end_date)
    end

    @summary_cards = [
      {
        title:    t("dashboard.cards.pending_specimens"),
        value:    stats[:pending_specimens],
        subtitle: t("dashboard.cards.pending_specimens_sub"),
        subtitle_tone: "rose",
        icon:     "ic-pending-specimen.svg"
      },
      {
        title:    t("dashboard.cards.in_progress_specimens"),
        value:    stats[:in_progress_specimens],
        subtitle: t("dashboard.cards.in_progress_specimens_sub", count: stats[:complete_specimens]),
        subtitle_tone: "emerald",
        icon:     "ic-processed-specimen.svg"
      },
      {
        title:    t("dashboard.cards.verified_works"),
        value:    stats[:verified_works],
        subtitle: t("dashboard.cards.verified_works_sub", count: stats[:total_works]),
        subtitle_tone: "gray",
        icon:     "ic-work-verif.svg"
      },
      {
        title:    t("dashboard.cards.validated_works"),
        value:    stats[:validated_works],
        subtitle: t("dashboard.cards.validated_works_sub"),
        subtitle_tone: "emerald",
        icon:     "ic-work-validated.svg"
      },
      {
        title:    t("dashboard.cards.blood_expiry"),
        value:    0,
        subtitle: t("dashboard.cards.blood_expiry_sub", count: 0),
        subtitle_tone: "gray",
        icon:     "ic-pending-specimen.svg"
      },
      {
        title:    t("dashboard.cards.qc_report"),
        value:    0,
        subtitle: t("dashboard.cards.qc_report_sub"),
        subtitle_tone: "gray",
        icon:     "ic-processed-specimen.svg"
      }
    ]

    @recent_specimens = Specimen.with_works
                            .for_range(@start_date, @end_date)
                            .where(status: :pending)
                            .order(created_at: :desc)
                            .limit(5)
    @recent_works = Work.with_details
                        .for_range(@start_date, @end_date)
                        .order(created_at: :desc)
                        .limit(5)

    # Mock data: bar chart per department (Waktu Pemrosesan)
    @processing_chart = {
      labels: [ "Hematologi", "Kimia Klinik", "Mikrobiologi", "Bank Darah", "Patologi" ],
      series: {
        lt_30:  [ 30, 32, 28, 33, 29 ],
        mid:    [ 55, 53, 56, 52, 54 ],
        gt_60:  [ 100, 100, 100, 100, 100 ]
      }
    }

    # Mock data: Statistik Waktu sidebar
    @time_stats = [
      { value: "54 menit",  tone: "emerald", label: t("dashboard.time_stats.avg_tat") },
      { value: "50%",       tone: "emerald", label: t("dashboard.time_stats.tat_ratio") },
      { value: "<61 menit", tone: "dark",    label: t("dashboard.time_stats.target") }
    ]
  end

  private

  # Parses start_date / end_date params. If both are blank, returns a 7-day window
  # ending today (so the dashboard is never empty on first visit).
  # If start_date is after end_date, swaps them.
  # Both dates are clamped to today (no future).
  def parse_range(raw_start, raw_end)
    today = Date.current

    start_date = parse_date(raw_start) || today - 6
    end_date   = parse_date(raw_end)   || today

    # Swap if reversed
    start_date, end_date = end_date, start_date if start_date > end_date

    # Clamp to today
    start_date = [ start_date, today ].min
    end_date   = [ end_date,   today ].min

    [ start_date, end_date ]
  end

  def parse_date(raw)
    return nil if raw.blank?

    Date.iso8601(raw)
  rescue ArgumentError, Date::Error
    nil
  end

  def cache_key_for(start_date, end_date)
    [ STATS_CACHE_KEY, "range", start_date.iso8601, end_date.iso8601 ].join("/")
  end

  def build_stats(start_date, end_date)
    work_counts     = Work.for_range(start_date, end_date).group(:status).count
    specimen_counts = Specimen.for_range(start_date, end_date).group(:status).count

    {
      pending_specimens:     specimen_counts["pending"] || 0,
      in_progress_specimens: specimen_counts["in_progress"] || 0,
      complete_specimens:    specimen_counts["complete"] || 0,
      validated_works:       work_counts["validated"] || 0,
      verified_works:        work_counts["verified"] || 0,
      total_works:           Work.for_range(start_date, end_date).count
    }
  end
end
