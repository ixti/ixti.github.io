# jekyll-excerpt
#
# Adds Post#excerpt that returns HTML of the first paragraph of a post.
# Based on Jekyll pull-request: https://github.com/mojombo/jekyll/pull/727
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
            to_liquid_without_excerpt.deep_merge({ 'excerpt' => self.excerpt })
          end
        end
      end

      module InstanceMethods

        attr_accessor :excerpt


        def read_yaml(*args)
          super
          self.excerpt = self.extract_excerpt
        end


        def transform
          super
          self.excerpt = converter.convert(self.excerpt)
        end


        protected


        # Internal: Extract excerpt from the content
        #
        # By default excerpt is your first paragraph of a post: everything
        # before the first two new lines:
        #
        #     ---
        #     title: Example
        #     ---
        #
        #     First paragraph with [link][1].
        #
        #     Second paragraph.
        #
        #     [1]: http://example.com/
        #
        # This is fairly good option for Markdown and Textile files. But might
        # cause problems for HTML posts (which is quiet unusual for Jekyll).
        # If default excerpt delimiter is not good for you, you might want to
        # set your own via configuration option `excerpt_separator`.
        #
        # For example, following is a good alternative for HTML posts:
        #
        #     # file: _config.yml
        #     excerpt_separator: "<!-- more -->"
        #
        # Notice that all markdown-style link references will be appended to the
        # excerpt. So the example post above will have this excerpt source:
        #
        #     First paragraph with [link][1].
        #
        #     [1]: http://example.com/
        #
        # Excerpts are rendered same time as content is rendered.
        #
        # Returns excerpt String
        def extract_excerpt
          separator     = self.site.config['excerpt_separator'] || "\n\n"
          head, _, tail = self.content.partition(separator)

          "" << head << "\n\n" << tail.scan(/^\[[^\]]+\]:.+$/).join("\n")
        end

      end
    end
  end
end


Jekyll::Post.send :include, Jekyll::ExcerptPlugin::PostPatch
