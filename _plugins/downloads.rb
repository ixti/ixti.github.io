# jekyll-downloads
#
# Provides easy way to "attach" zipballs for the pages.
#
# USAGE:
#
# Put necessary files under `_downloads/<uniq-name>/` diretory, and then use
# {% downloadable <uniq-name> %} in your templates to get link to the zipball.
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
require 'zip/zip'


module Jekyll
  module DownloadsPlugin
    module Logging
      protected
      def log level, message
        puts "[DownloadsPlugin] #{level.to_s.upcase} #{message}"
      end
    end # class Logging


    class Configuration < OpenStruct
      @@defaults = {
        :sources => '_downloads',
        :dirname => 'downloads'
      }

      def initialize config = {}
        super @@defaults.merge(config)
        self.dirname = self.dirname.gsub(/^\/+|\/+$/, '')
      end
    end # class Configuration


    module SitePatch
      def downloads_config
        @downloads_config ||= Configuration.new(self.config['downloads'] || {})
      end

      def has_downloadable? name
        Dir.exists? File.join(self.source, self.downloads_config.sources, name)
      end
    end # module SitePatch


    class ZipBall
      def initialize site, source
        @site, @source = site, source
      end

      def destination dest
        File.join(dest, @site.downloads_config.dirname, filename)
      end

      def filename
        "#{@source.basename}.zip"
      end

      def write path
        dest_path = destination(path)

        FileUtils.mkdir_p File.dirname(dest_path)
        FileUtils.rm_f dest_path if File.exists? dest_path

        Zip::ZipFile.open(dest_path, Zip::ZipFile::CREATE) do |zipfile|
          @source.find do |file|
            zipfile.add(file.relative_path_from(@source.parent).to_s, file.to_s)
          end
        end

        true
      end
    end # class ZipBall


    class Generator < ::Jekyll::Generator
      def generate site
        sources = Pathname.new(site.source).join(site.downloads_config.sources)

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

        "/#{site.downloads_config.dirname}/#{CGI.escape name}.zip"
      end
    end
  end
end


Jekyll::Site.send :include, Jekyll::DownloadsPlugin::SitePatch


Liquid::Template.register_filter Jekyll::DownloadsPlugin::Filters
