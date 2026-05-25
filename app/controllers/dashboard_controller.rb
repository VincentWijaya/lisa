class DashboardController < ApplicationController
  before_action :authenticate_user!

  STATS_CACHE_KEY = "dashboard/stats"
  STATS_TTL = 2.minutes

  def index
    stats = Rails.cache.fetch(STATS_CACHE_KEY, expires_in: STATS_TTL) do
      work_counts = Work.group(:status).count

      {
        specimens: Specimen.count,
        pending_works: work_counts["pending"] || 0,
        validated_works: work_counts["validated"] || 0,
        verified_works: work_counts["verified"] || 0
      }
    end

    @summary_cards = [
      { title: I18n.t("dashboard.cards.specimens"),       value: stats[:specimens],       tone: "bg-slate-900 text-white" },
      { title: I18n.t("dashboard.cards.pending_works"),   value: stats[:pending_works],   tone: "bg-amber-100 text-amber-900" },
      { title: I18n.t("dashboard.cards.validated_works"), value: stats[:validated_works], tone: "bg-sky-100 text-sky-900" },
      { title: I18n.t("dashboard.cards.verified_works"),  value: stats[:verified_works],  tone: "bg-emerald-100 text-emerald-900" }
    ]

    @recent_works    = Work.with_details.order(created_at: :desc).limit(10)
    @recent_specimens = Specimen.with_works.order(created_at: :desc).limit(10)
  end
end
