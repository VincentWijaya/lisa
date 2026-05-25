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
end
