class ReportMailer < ApplicationMailer
  def specimen_report(specimen, pdf_bytes, recipient_email)
    @specimen = specimen
    @lab_name = ENV.fetch("LAB_NAME", "LABORATORIUM")

    attachments["laporan_#{specimen.order_number}.pdf"] = {
      mime_type: "application/pdf",
      content: pdf_bytes
    }

    mail(
      to: recipient_email,
      subject: "Hasil Laboratorium – #{specimen.order_number} (#{specimen.patient_name})"
    )
  end
end
