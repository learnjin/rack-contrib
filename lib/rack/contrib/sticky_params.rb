require 'nokogiri'
require 'byebug'

module Rack

  # A Rack middleware for keeping parameters through requests
  #
  # Kai Rubarth
  #
  class StickyParams
    include Rack::Utils

    def initialize(app, sticky_parameter_keys, mime_types = ['text/html'] )
      @app = app
      @sticky_parameter_keys = sticky_parameter_keys
      @mime_types = mime_types
    end

    def call(env)
      request = Rack::Request.new(env)

      status, headers, body = @app.call(env)

      headers = HeaderHash.new(headers)

      if status == 200 && is_supported_mime?(headers)
        #return bad_request unless valid_callback?(callback)
        #

        params = Rack::Utils.parse_query(request.query_string)

        sticky_params = params.select{|k,v| @sticky_parameter_keys.include? k}

        body = weave(sticky_params, body)

        # Set new Content-Length, if it was set before we mutated the response body
        if headers['Content-Length']
          length = body.to_ary.inject(0) { |len, part| len + bytesize(part) }
          headers['Content-Length'] = length.to_s
        end

      end

      [status, headers, body]
    end

    private

    def weave(sticky_params, content)
      return content if sticky_params == {}
      new_result = []

      content.each do |line|
        targets = line.scan(Regexp.new('|<a href="(/[^"]+)')).flatten.uniq
        puts targets.inspect
        res = line

        targets.each do |href|
          path, query = href.split('?')
          request_params = Rack::Utils.parse_query(query)

          request_params.merge!(sticky_params)

          new_target = path + '?' + Rack::Utils.build_query(request_params)
         
          #res.gsub!(/<a\s+href="\/#{href}"/, %Q|<a href="#{new_target}"|)
          res.gsub!(Regexp.new(%Q|<a href="#{href}")|), %Q|<a href="#{new_target}"|)
        end

        new_result << res
      end

      new_result
    end


    def is_supported_mime?(headers)
      return false unless headers.key?('Content-Type')
      
      @mime_types.each do |mime|
        return true if headers['Content-Type'].include?(mime)
      end

      false
    end

    def bad_request(body = "Bad Request")
      [ 400, { 'Content-Type' => 'text/plain', 'Content-Length' => body.size.to_s }, [body] ]
    end

  end
end
