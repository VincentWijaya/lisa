module ApplicationHelper
  def action_icon_link(label, url, icon:, tone: :secondary, **html_options)
    html_options[:class] = [action_icon_button_classes(tone), html_options[:class]].compact.join(" ")
    html_options[:title] = label
    html_options[:aria] = { label: label }.merge(html_options[:aria] || {})

    link_to url, html_options do
      safe_join([action_icon(icon), content_tag(:span, label, class: "sr-only")])
    end
  end

  def action_icon_button(label, url, icon:, method:, tone: :primary, disabled: false)
    button_to url,
              method: method,
              disabled: disabled,
              class: action_icon_button_classes(tone, disabled: disabled),
              form: { class: "inline-flex" },
              title: label,
              aria: { label: label, disabled: disabled } do
      safe_join([action_icon(icon), content_tag(:span, label, class: "sr-only")])
    end
  end

  def action_icon_button_classes(tone = :secondary, disabled: false)
    base = "inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-lg text-sm transition"
    return "#{base} cursor-not-allowed border border-slate-200 bg-slate-100 text-slate-400" if disabled

    tones = {
      primary: "border border-slate-900 bg-slate-900 text-white hover:bg-slate-700",
      secondary: "border border-slate-300 bg-white text-slate-700 hover:bg-slate-50",
      success: "border border-emerald-600 bg-emerald-600 text-white hover:bg-emerald-500"
    }

    "#{base} #{tones.fetch(tone)}"
  end

  def action_icon(name)
    paths = case name
            when :eye
              [
                tag.path(d: "M2.25 12s3.75-6.75 9.75-6.75S21.75 12 21.75 12s-3.75 6.75-9.75 6.75S2.25 12 2.25 12Z"),
                tag.circle(cx: "12", cy: "12", r: "2.75")
              ]
            when :barcode
              [
                tag.path(d: "M4 6v12"),
                tag.path(d: "M7 6v12"),
                tag.path(d: "M11 6v12"),
                tag.path(d: "M13 6v12"),
                tag.path(d: "M17 6v12"),
                tag.path(d: "M20 6v12")
              ]
            when :check
              [tag.path(d: "m5 12 4 4L19 6")]
            when :badge_check
              [
                tag.path(d: "M12 3.25 14.4 5l2.95-.15.75 2.85 2.15 2.05L19 12.4l.4 2.95-2.65 1.3-1.55 2.55-3.2-.8-3.2.8-1.55-2.55-2.65-1.3L5 12.4 3.75 9.75 5.9 7.7l.75-2.85L9.6 5 12 3.25Z"),
                tag.path(d: "m8.75 12 2.25 2.25L15.75 9.5")
              ]
            else
              raise ArgumentError, "Unknown action icon: #{name}"
            end

    tag.svg(
      class: "h-4 w-4",
      xmlns: "http://www.w3.org/2000/svg",
      fill: "none",
      viewBox: "0 0 24 24",
      stroke: "currentColor",
      "stroke-width": "2",
      "stroke-linecap": "round",
      "stroke-linejoin": "round",
      "aria-hidden": "true"
    ) do
      safe_join(paths)
    end
  end
end
