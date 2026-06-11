require "base64"
require "barby"
require "barby/barcode/code_128"
require "barby/outputter/png_outputter"

module WorksHelper
  def barcode_data_uri(barcode_id)
    barcode = Barby::Code128B.new(barcode_id)
    png = Barby::PngOutputter.new(barcode).to_png(height: 60, xdim: 2, margin: 0)
    "data:image/png;base64,#{Base64.strict_encode64(png)}"
  end

  def work_status_classes(status)
    case status
    when "verified" then "bg-emerald-100 text-emerald-800"
    when "validated" then "bg-sky-100 text-sky-800"
    when "cancelled" then "bg-rose-100 text-rose-800"
    else "bg-amber-100 text-amber-800"
    end
  end

  def work_display_name(work)
    work.test_codes_text.presence || work.examination.name
  end

  def work_result_value(work)
    result = work.latest_result
    return "-" unless result

    [result.result_value, result.result_unit.presence].compact.join(" ")
  end

  def work_interpretation_label(work)
    work.latest_result&.interpretation&.humanize || "-"
  end

  def work_interpretation_badge(work)
    label = work_interpretation_label(work)
    return label if label == "-"

    content_tag(:span, label, class: "rounded-full px-3 py-1 text-xs font-semibold #{interpretation_classes(work.latest_result&.interpretation)}")
  end

  def reference_rule_display(result)
    rule = result.reference_rule
    return "-" unless rule

    rule.name
  end

  def reference_range_display(result)
    rule = result.reference_rule
    return "-" unless rule

    if rule.numeric? && (rule.numeric_low_value.present? || rule.numeric_high_value.present?)
      low  = rule.numeric_low_value&.to_s&.delete_suffix(".0000").presence || rule.numeric_low_value&.to_f&.to_s
      high = rule.numeric_high_value&.to_s&.delete_suffix(".0000").presence || rule.numeric_high_value&.to_f&.to_s
      range = [low, high].compact.join(" – ")
      unit  = rule.unit.presence || result.result_unit.presence
      [range, unit].compact.join(" ")
    elsif rule.reference_value.present?
      rule.reference_value
    elsif rule.normal_values.present?
      rule.normal_values.join(", ")
    else
      "-"
    end
  end

  def primary_action_button_classes(tone = "bg-slate-900 hover:bg-slate-700")
    "rounded-lg #{tone} px-3 py-2 text-xs font-semibold text-white"
  end

  def secondary_action_button_classes
    "rounded-lg border border-slate-300 px-3 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-50"
  end

  def work_table_actions(work)
    content_tag(:div, class: "flex items-center gap-2", data: { controller: "barcode-scanner" }) do
      safe_join([work_table_action_buttons(work), work_scan_validation_modal(work)].compact)
    end
  end

  def work_table_action_buttons(work)
    safe_join(
      [
        action_icon_link(t("works.actions.view"), work_path(work), icon: :eye),
        action_icon_link(t("works.actions.print_barcode"), barcode_label_work_path(work), icon: :barcode, target: "_blank", rel: "noopener"),
        action_icon_trigger(t("works.actions.validate"), icon: :check, disabled: !work.pending?, data: (work.pending? ? { action: "click->barcode-scanner#open" } : {})),
        action_icon_button(t("works.actions.verify"), verify_work_work_path(work), icon: :badge_check, method: :patch, tone: :success, disabled: !work.validated?)
      ],
      " "
    )
  end

  def work_scan_validation_modal(work)
    return unless work.pending?

    render "works/scan_validation_modal", work: work
  end

  private

  def interpretation_classes(interpretation)
    case interpretation
    when "critical" then "bg-rose-100 text-rose-800"
    when "abnormal" then "bg-amber-100 text-amber-800"
    else "bg-emerald-100 text-emerald-800"
    end
  end
end
