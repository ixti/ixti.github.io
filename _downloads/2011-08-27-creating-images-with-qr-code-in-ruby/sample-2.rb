require 'rqrcode'
require 'RMagick'

# usage: ruby sample-2.rb "http://www.example.com" /tmp/demo.png
# "QR Code" is registered trademark of DENSO WAVE INCORPORATED

INPUT   = ARGV[0]
OUTPUT  = ARGV[1]
SCALE   = 4


# prepare qr and img objects
qr    = RQRCode::QRCode.new(INPUT)
size  = qr.modules.count * SCALE
img   = Magick::Image.new(size, size)


# draw matrix
qr.modules.each_index do |r|
  row = r * SCALE

  qr.modules.each_index do |c|
    col = c * SCALE
    dot = Magick::Draw.new

    dot.fill(qr.dark?(r, c) ? 'black' : 'white')
    dot.rectangle(col, row, col + SCALE, row + SCALE)
    dot.draw(img)
  end
end


# produce image
img.write OUTPUT
