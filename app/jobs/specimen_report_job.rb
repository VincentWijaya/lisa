class SpecimenReportJob < ApplicationJob
  queue_as :default

  def perform(specimen_id, recipient_email)
    specimen = Specimen.includes(works: { examination_results: :reference_rule }).find(specimen_id)
    return unless specimen

    html = render_report_html(specimen)
    pdf = Grover.new(html, format: "A4", margin: { top: "10mm", bottom: "15mm", left: "12mm", right: "12mm" }).to_pdf

    ReportMailer.specimen_report(specimen, pdf, recipient_email).deliver_now
  end

  private

  def render_report_html(specimen)
    works = specimen.works.includes(:examination, examination_results: :reference_rule).order(:label_sequence).to_a

    gender_enum = ReferenceRule.specimen_gender_to_enum(specimen.gender)
    allowed_gender_values = gender_enum ? [ nil, gender_enum ] : [ nil ]
    allowed_ref_rule_ids = ReferenceRule.active
      .where(gender: allowed_gender_values)
      .pluck(:id)

    results_by_work_id = works.each_with_object({}) do |work, hash|
      results = work.examination_results
        .select { |r| r.result_value.present? }
        .select { |r| allowed_ref_rule_ids.include?(r.reference_rule_id) }
        .sort_by { |r| [ -r.created_at.to_i, -r.id ] }
        .group_by(&:reference_rule_id)
        .transform_values(&:first)
        .values
        .sort_by(&:reference_rule_id)
      hash[work.id] = results
    end

    works_with_results = works.select { |w| (results_by_work_id[w.id] || []).any? }
    grouped_works      = works_with_results.group_by { |w| w.examination.category.presence || "UMUM" }
    collection_times   = collection_times_by_type(works_with_results)
    validator          = find_validator(works_with_results)

    ApplicationController.render(
      template: "specimens/print_report",
      layout: "lab_report",
      assigns: {
        specimen: specimen,
        works: works,
        results_by_work_id: results_by_work_id,
        grouped_works: grouped_works,
        collection_times: collection_times,
        validator: validator
      }
    )
  end

  def collection_times_by_type(works)
    works
      .select { |w| w.specimen_type.present? && w.sample_taken_datetime.present? }
      .group_by(&:specimen_type)
      .transform_values { |ws| ws.min_by(&:sample_taken_datetime).sample_taken_datetime }
  end

  def find_validator(works)
    verifier_ids = works.flat_map(&:examination_results).filter_map(&:verified_by).uniq
    User.find_by(id: verifier_ids.first) if verifier_ids.any?
  end
end
