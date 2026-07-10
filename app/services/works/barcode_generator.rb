module Works
  class BarcodeGenerator
    def initialize(specimen:, label_sequence:, examination: nil, examinations: nil, manual_input: false)
      @specimen = specimen
      @examinations = Array(examinations || examination)
      @label_sequence = label_sequence
      @manual_input = manual_input
    end

    def create!
      specimen.works.create!(
        examination: primary_examination,
        barcode_id: barcode_id,
        label_sequence: label_sequence,
        specimen_type: specimen_type,
        test_codes_text: test_codes_text,
        sample_taken_datetime: specimen.collection_datetime,
        status: Work.statuses[:pending],
        manual_input: manual_input
      )
    end

    private

    attr_reader :specimen, :examinations, :label_sequence, :manual_input

    def primary_examination
      examinations.first
    end

    def barcode_id
      "#{specimen.order_number}-#{format('%02d', label_sequence)}"
    end

    def specimen_type
      examinations.map(&:specimen_type).compact_blank.first
    end

    def test_codes_text
      codes = examinations.map { |examination| examination.code.to_s.strip }.reject(&:blank?)
      return if codes.empty?

      "#{codes.join('; ')};"
    end
  end
end
