module ApplicationHelper
  def text_field_classes
    "block w-full rounded-lg border border-slate-300 px-3 py-2 text-sm shadow-sm focus:border-sky-500 focus:outline-none focus:ring-1 focus:ring-sky-500"
  end

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

  def action_icon_trigger(label, icon:, tone: :primary, disabled: false, **html_options)
    html_options[:class] = [action_icon_button_classes(tone, disabled: disabled), html_options[:class]].compact.join(" ")
    html_options[:title] = label
    html_options[:disabled] = disabled
    html_options[:type] = "button"
    html_options[:aria] = { label: label, disabled: disabled }.merge(html_options[:aria] || {})

    button_tag(**html_options) do
      safe_join([action_icon(icon), content_tag(:span, label, class: "sr-only")])
    end
  end

  def action_icon_button_classes(tone = :secondary, disabled: false)
    base = "inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-md text-sm transition"
    return "#{base} cursor-not-allowed border border-slate-200 bg-slate-100 text-slate-400" if disabled

    tones = {
      primary: "border border-slate-900 bg-slate-900 text-white hover:bg-slate-700",
      secondary: "text-slate-600 hover:bg-slate-100",
      success: "border border-emerald-600 bg-emerald-600 text-white hover:bg-emerald-500"
    }

    "#{base} #{tones.fetch(tone)}"
  end

  def whatsapp_action_link(label, url, **html_options)
    html_options[:class] = ["inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-md bg-[#cefde3] text-[#2f6740] transition hover:bg-[#b8f5cd]", html_options[:class]].compact.join(" ")
    html_options[:title] = label
    html_options[:aria] = { label: label }.merge(html_options[:aria] || {})
    html_options[:data] = { turbo_frame: "_top" }.merge(html_options[:data] || {})

    link_to url, html_options do
      safe_join([action_icon(:whatsapp), content_tag(:span, label, class: "sr-only")])
    end
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
            when :email
              [
                tag.path(d: "M21.75 6.75v10.5a2.25 2.25 0 0 1-2.25 2.25h-15a2.25 2.25 0 0 1-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0 0 19.5 4.5h-15a2.25 2.25 0 0 0-2.25 2.25m19.5 0v.243a2.25 2.25 0 0 1-1.07 1.916l-7.5 4.615a2.25 2.25 0 0 1-2.36 0L3.32 8.91a2.25 2.25 0 0 1-1.07-1.916V6.75")
              ]
            when :whatsapp
              [
                tag.path(d: "M20.52 3.48A11.94 11.94 0 0 0 12.06 0C5.46 0 .12 5.34.12 11.94c0 2.1.55 4.16 1.6 5.97L0 24l6.27-1.64a11.93 11.93 0 0 0 5.79 1.48h.01c6.6 0 11.94-5.34 11.94-11.94 0-3.19-1.24-6.19-3.49-8.42ZM12.07 21.8h-.01a9.85 9.85 0 0 1-5.02-1.38l-.36-.21-3.72.98 1-3.63-.24-.37a9.86 9.86 0 0 1 15.2-12.27 9.74 9.74 0 0 1 2.88 6.95c0 5.44-4.43 9.87-9.86 9.87Zm5.46-7.36c-.3-.15-1.77-.87-2.04-.97-.27-.1-.47-.15-.67.15s-.77.97-.94 1.17c-.17.2-.35.22-.65.07-.3-.15-1.26-.46-2.4-1.48-.89-.79-1.49-1.77-1.66-2.07-.17-.3-.02-.46.13-.61.13-.13.3-.35.45-.52.15-.17.2-.3.3-.5.1-.2.05-.37-.02-.52-.07-.15-.67-1.62-.92-2.22-.24-.58-.49-.5-.67-.51l-.57-.01c-.2 0-.52.07-.79.37s-1.05 1.02-1.05 2.5 1.07 2.9 1.22 3.1c.15.2 2.11 3.22 5.11 4.52.71.31 1.27.49 1.7.63.71.23 1.36.2 1.87.12.57-.08 1.77-.72 2.02-1.42.25-.7.25-1.29.17-1.42-.07-.13-.27-.2-.57-.35Z")
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
