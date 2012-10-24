# jekyll-qr_code
#
# Copyright (C) 2012 Aleksey V Zapparov (http://ixti.net/)
#
# The MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the “Software”), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do
# so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


# 3rd party libs
require 'rqrcode'
require 'RMagick'


module Jekyll
  module QRCodePlugin
    module Filters
      def qr_code_image str
        return str unless str

        qr      = RQRCode::QRCode.new(str, :size => 10, :level => :l )
        scale   = 2
        size    = qr.modules.count * scale
        img     = Magick::Image.new(size, size)

        # draw matrix
        qr.modules.each_index do |r|
          row = r * scale

          qr.modules.each_index do |c|
            col, dot = c * scale, Magick::Draw.new

            dot.fill(qr.dark?(r, c) ? 'black' : 'white')
            dot.rectangle(col, row, col + scale, row + scale)
            dot.draw(img)
          end
        end

        blob = img.to_blob { self.format = 'GIF' }
        img.destroy!

        data = Base64.encode64(blob.to_s).gsub(/\s+/, "")
        data = "data:image/gif;base64,#{CGI.escape(data)}"

        '<img src="%s" width="%d" height="%d">' % [ data, size, size ]
      end
    end
  end
end


Liquid::Template.register_filter Jekyll::QRCodePlugin::Filters
