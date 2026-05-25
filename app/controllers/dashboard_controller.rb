class DashboardController < ApplicationController
  def index
    @summary_cards = [
      { title: "Specimens", value: Specimen.count, tone: "bg-slate-900 text-white" },
      { title: "Pending Works", value: Work.pending.count, tone: "bg-amber-100 text-amber-900" },
      { title: "Validated Works", value: Work.validated.count, tone: "bg-sky-100 text-sky-900" },
      { title: "Verified Works", value: Work.verified.count, tone: "bg-emerald-100 text-emerald-900" }
    ]

    @recent_works = Work.with_details.order(created_at: :desc).limit(10)
    @recent_specimens = Specimen.with_works.order(created_at: :desc).limit(10)
  end
end
