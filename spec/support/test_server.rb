# frozen_string_literal: true

require 'rubygems'
require 'rack'

module Httplog
  module Test
    class Server
      def call(env)
        @root = __dir__
        path = Rack::Utils.unescape(env['PATH_INFO'])
        path += 'index.html' if path == '/'
        file = @root + path.to_s

        params = Rack::Utils.parse_nested_query(env['QUERY_STRING'])

        headers = { 'Content-Type' => 'text/html' }

        if params['redirect']
          [301, { 'Location' => '/index.html' }, '']

        elsif File.exist?(file)
          headers['Content-Type'] = 'application/octet-stream' if File.extname(file) == '.bin'
          headers['Content-Type'] = 'application/pdf' if File.extname(file) == '.pdf'
          headers['Content-Type'] = 'text/html; charset=UTF-8' if path =~ /utf8/
          headers['Content-Encoding'] = 'gzip' if File.extname(file) == '.gz'
          [200, headers, File.binread(file)]
        else
          [404, { 'Content-Type' => 'text/plain' }, 'file not found']
        end
      end
    end
  end
end
