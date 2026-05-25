module Works
  class BarcodeGenerator
    def initialize(specimen:, examination:, label_sequence:)
      @specimen = specimen
      @examination = examination
      @label_sequence = label_sequence
    end

    def create!
      specimen.works.create!(
        examination: examination,
        barcode_id: barcode_id,
        label_sequence: label_sequence,
        specimen_type: examination.specimen_type,
        test_codes_text: test_codes_text,
        sample_taken_datetime: specimen.collection_datetime,
        status: Work.statuses[:pending]
      )
    end

    private

    attr_reader :specimen, :examination, :label_sequence

    def barcode_id
      "#{specimen.order_number}-#{format('%02d', label_sequence)}"
    end

    def test_codes_text
      code = examination.code.to_s.strip
      return if code.blank?

      "#{code};"
    end
  end
end
