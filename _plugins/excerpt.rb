# jekyll-excerpt
#
# Adds Post#excerpt that returns HTML of the first paragraph of a post.
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


module Jekyll
  module ExcerptPlugin
    module PostPatch
      def self.included base
        base.send :include, InstanceMethods

        base.class_eval do
          alias_method :to_liquid_without_excerpt, :to_liquid

          def to_liquid
            to_liquid_without_excerpt.deep_merge({ 'excerpt' => excerpt })
          end
        end
      end

      module InstanceMethods
        def excerpt
          unless @excerpt
            raw  = File.read(File.join(@base, @name))

            # strip out YAML front-matter block
            if raw =~ /^(---\s*\n.*?\n?)^(---\s*$\n?)/m
              raw = $POSTMATCH
            end

            raw.strip!

            head = raw.partition("\n\n").first
            refs = raw.scan(/^\[[^\]]+\]:.+$/).join "\n"

            @excerpt = converter.convert "#{head}\n\n#{refs}"
          end

          @excerpt
        end
      end
    end
  end
end


Jekyll::Post.send :include, Jekyll::ExcerptPlugin::PostPatch
