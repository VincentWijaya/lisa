module SpecimensHelper
  def specimen_status_classes(status)
    case status
    when "complete" then "bg-emerald-100 text-emerald-800"
    when "cancelled" then "bg-rose-100 text-rose-800"
    when "in_progress" then "bg-sky-100 text-sky-800"
    else "bg-amber-100 text-amber-800"
    end
  end

  def specimen_summary(specimen)
    [specimen.medical_record_id, specimen.age_in_years&.then { |age| "#{age} years" }, specimen.gender].compact.join(" • ")
  end
end
