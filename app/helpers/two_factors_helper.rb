module TwoFactorsHelper
  QR_QUIET_ZONE = 4

  # Draws +text+ as an inline SVG QR code. The SVG is built with tag helpers
  # from the module matrix, so nothing is marked html_safe by hand.
  def qr_code_svg(text, label:)
    modules = RQRCode::QRCode.new(text, level: :m).modules
    size = modules.size + QR_QUIET_ZONE * 2

    path = modules.each_with_index.flat_map do |row, y|
      row.each_with_index.filter_map do |dark, x|
        "M#{x + QR_QUIET_ZONE} #{y + QR_QUIET_ZONE}h1v1h-1z" if dark
      end
    end.join

    tag.svg(xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 #{size} #{size}",
      role: "img", aria: { label: label }, class: "w-48 h-48 sm:w-56 sm:h-56 bg-white",
      "shape-rendering": "crispEdges") do
      tag.rect(width: size, height: size, fill: "#ffffff") + tag.path(d: path, fill: "#051c2c")
    end
  end
end
