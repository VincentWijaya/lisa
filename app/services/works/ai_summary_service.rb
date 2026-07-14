module Works
  class AiSummaryService
    MODEL = OpenaiConfig::MODEL
    PROMPT = "Buat analisa indikasi dan saran yang harus dilakukan dari hasil tes sample. Singkat dan mudah dimengerti".freeze

    def self.call(work)
      new(work).call
    end

    def initialize(work)
      @work = work
    end

    def call
      return ServiceResult.failure(errors: ["OPENAI_KEY belum diset"]) if ENV["OPENAI_KEY"].blank?
      return ServiceResult.failure(errors: ["Belum ada hasil pemeriksaan"]) if examination_payload.blank?

      response = client.chat.completions.create(
        model: MODEL,
        temperature: 0.3,
        messages: [
          { role: "system", content: system_prompt },
          { role: "user", content: user_prompt }
        ]
      )

      content = response.choices.first&.message&.content.to_s.strip
      return ServiceResult.failure(errors: ["Respons AI kosong"]) if content.empty?

      @work.update!(ai_summary: content)
      ServiceResult.success(work: @work, summary: content)
    rescue OpenAI::Errors::Error => e
      ServiceResult.failure(errors: ["OpenAI error: #{e.message}"])
    rescue StandardError => e
      ServiceResult.failure(errors: [e.message])
    end

    private

    attr_reader :work

    def client
      @client ||= OpenAI::Client.new(api_key: ENV["OPENAI_KEY"])
    end

    def system_prompt
      "Kamu adalah asisten laboratorium klinik. Jawab dalam bahasa Indonesia. " \
        "Berikan analisa indikasi klinis dan saran tindak lanjut berdasarkan data hasil lab. " \
        "Sebutkan hasil yang abnormal/kritis secara eksplisit. Jawaban singkat dan mudah dimengerti. " \
        "Jangan tambahkan disclaimer panjang. Jangan mengarang nilai yang tidak ada di data."
    end

    def specimen
      @specimen ||= work.specimen
    end

    def user_prompt
      parts = []
      parts << "PROMPT: #{PROMPT}"
      parts << ""
      parts << "DATA PASIEN & SPESIMEN:"
      parts << "  No. Order: #{specimen.order_number}"
      parts << "  Barcode: #{work.barcode_id}"
      parts << "  Pasien: #{specimen.patient_name} (ID: #{specimen.patient_id})"
      parts << "  RM: #{specimen.medical_record_id}" if specimen.medical_record_id.present?
      parts << "  Tanggal Lahir: #{specimen.birth_date}" if specimen.birth_date.present?
      parts << "  Jenis Kelamin: #{specimen.gender}" if specimen.gender.present?
      parts << "  Diagnosa Awal: #{specimen.dianognes}" if specimen.dianognes.present?
      parts << ""
      parts << "PEMERIKSAAN:"
      parts << "  #{work.examination.name} (Kategori: #{work.examination.category}, Kode: #{work.examination.code})"
      parts << ""
      parts << "HASIL PEMERIKSAAN:"
      parts.concat(examination_payload)

      parts.join("\n")
    end

    def examination_payload
      results = work.examination_results.includes(:reference_rule).order(:id)
      lines = []
      results.each do |result|
        lines << "  * #{result_line(result)}"
      end
      lines
    end

    def result_line(result)
      rule = result.reference_rule
      base = "#{rule&.name || 'Hasil'}: #{result.result_value} #{rule&.unit.to_s.presence}"
      if rule.present?
        range = numeric_range(rule)
        base += " (Ref: #{range})" if range.present?
        interp = result.interpretation.presence || rule.interprets?(result.result_value)
        base += " [#{interp.upcase}]" if interp.present?
      end
      base
    end

    def numeric_range(rule)
      return nil unless rule.result_type == "numeric"

      low  = rule.numeric_low_value
      high = rule.numeric_high_value
      return "#{low} - #{high}" if low.present? && high.present?
      return ">= #{low}" if low.present?
      return "<= #{high}" if high.present?
      nil
    end
  end
end
