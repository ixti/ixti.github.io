# jekyll-zipballs
#
# Provides easy way to "attach" zipballs for the pages.
#
# USAGE:
#
# Put necessary files under `_zipballs/<uniq-name>/` directory, and then use
# {{ <uniq-name> | zipball_link }} in your templates to get link of the zipball.
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


# stdlib
require 'pathname'
require 'fileutils'
require 'ostruct'
require 'set'


# 3rd-party
require 'zip'


module Jekyll
  module ZipballPlugin
    module Logging
      protected
      def log level, message
        puts "[ZipballPlugin] #{level.to_s.upcase} #{message}"
      end
    end # class Logging


    class Configuration < OpenStruct
      @@defaults = {
        :sources => '_zipballs',
        :dirname => 'zipballs'
      }

      def initialize config = {}
        super @@defaults.merge(config)
        self.dirname = self.dirname.gsub(/^\/+|\/+$/, '')
      end
    end # class Configuration


    module SitePatch
      def zipballs_config
        @zipballs_config ||= Configuration.new(self.config['zipballs'] || {})
      end

      def has_downloadable? name
        Dir.exists? File.join(self.source, self.zipballs_config.sources, name)
      end
    end # module SitePatch


    class ZipBall
      def initialize site, source
        @site, @source = site, source
      end

      def destination dest
        File.join(dest, @site.zipballs_config.dirname, filename)
      end

      def filename
        "#{@source.basename}.zip"
      end

      def write path
        dest_path = destination(path)

        FileUtils.mkdir_p File.dirname(dest_path)
        FileUtils.rm_f dest_path if File.exists? dest_path

        Zip::File.open(dest_path, Zip::File::CREATE) do |zipfile|
          @source.find do |file|
            zipfile.add(file.relative_path_from(@source.parent).to_s, file.to_s)
          end
        end

        true
      end
    end # class ZipBall


    class Generator < ::Jekyll::Generator
      include Logging

      def generate site
        sources = Pathname.new(site.source).join(site.zipballs_config.sources)

        unless sources.directory?
          log :warn, "Sources not found: #{site.zipballs_config.sources}"
          return
        end

        sources.children.each do |source|
          next unless source.directory?
          site.static_files << ZipBall.new(site, source)
        end
      end
    end # class Generator


    module Filters
      include Logging

      LINK = '<a href="%s">%s</a>'

      def zipball_link name
        return name.map { |n| zipball_link n } if name.is_a? Array
        LINK % [ zipball_url(name), "#{name}.zip" ]
      end

      def zipball_url name
        site = @context.registers[:site]

        unless site.has_downloadable? name
          log :error, "Can't find sources for zipball: #{name}"
          return
        end

        "/#{site.zipballs_config.dirname}/#{CGI.escape name}.zip"
      end
    end
  end
end


Jekyll::Site.send :include, Jekyll::ZipballPlugin::SitePatch


Liquid::Template.register_filter Jekyll::ZipballPlugin::Filters
