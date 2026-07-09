module SpecimensHelper
  def specimen_status_classes(status)
    case status
    when "complete" then "bg-[#cefde3] text-[#2f6740]"
    when "cancelled" then "bg-rose-100 text-rose-800"
    when "in_progress" then "bg-sky-100 text-sky-800"
    else "bg-[#fceeb3] text-[#b28c2f]"
    end
  end

  def specimen_summary(specimen)
    [specimen.medical_record_id, specimen.age_in_years&.then { |age| "#{age} years" }, specimen.gender].compact.join(" • ")
  end

  # Comma-separated, de-duplicated list of work category names
  # (e.g. "Hematologi, Kimia"). Falls back to "-" when no works.
  def specimen_work_list(specimen)
    names = specimen.works
                   .includes(:examination)
                   .map { |w| w.examination&.category.to_s.titleize }
                   .reject { |c| c.blank? || c == "-" }
                   .uniq
    names.any? ? names.join(", ") : "-"
  end

  # Returns the formatted reference range string for display in the report.
  def format_reference_range(reference_rule)
    return "" unless reference_rule

    return reference_rule.reference_value if reference_rule.reference_value.present?

    if reference_rule.result_type == "numeric"
      low  = reference_rule.numeric_low_value
      high = reference_rule.numeric_high_value
      if low && high
        "#{low.to_f.then { |v| v == v.to_i ? v.to_i : v }} - #{high.to_f.then { |v| v == v.to_i ? v.to_i : v }}"
      elsif low
        ">= #{low}"
      elsif high
        "<= #{high}"
      else
        ""
      end
    elsif reference_rule.normal_values.present?
      reference_rule.normal_values.join(", ")
    else
      ""
    end
  end

  # Returns "Tahun X Bulan Y Hari Z" style age string, matching Indonesian lab report format.
  def full_age_display(birth_date, as_of = Date.current)
    return "" unless birth_date

    years  = as_of.year - birth_date.year
    months = as_of.month - birth_date.month
    days   = as_of.day - birth_date.day

    if days < 0
      months -= 1
      days += Date.new(as_of.year, as_of.month, 1).prev_month.then { |d| Date.new(d.year, d.month, -1).day }
    end

    if months < 0
      years -= 1
      months += 12
    end

    "#{years} Tahun #{months} Bulan #{days} Hari"
  end

  # Returns "*" flag for abnormal/critical interpretation (matching lab report convention).
  def result_flag(interpretation)
    %w[abnormal critical].include?(interpretation) ? "*" : ""
  end
end
