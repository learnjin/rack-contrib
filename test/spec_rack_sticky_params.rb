require 'test/spec'
require 'rack/mock'
require 'rack/contrib/sticky_params'
require 'rack/mime'

context "Rack::StickyParams" do


  specify "should append the sticky parameter in the response body if HTML" do
    app_body = '<html><a href="/">Root</a></html>'
    app = lambda { |env| [200, {'Content-Type' => 'text/html'}, [app_body]] }
    request = Rack::MockRequest.env_for("/", :params => "sticky=there")
    body = Rack::StickyParams.new(app, ['sticky']).call(request).last
    body.should.equal ['<html><a href="/?sticky=there">Root</a></html>']
  end

  specify "should not append sticky parameter in the response body if parameter is missing" do
    app_body = '<html><a href="/">Root</a></html>'
    app = lambda { |env| [200, {'Content-Type' => 'text/html'}, [app_body]] }
    request = Rack::MockRequest.env_for("/")
    body = Rack::StickyParams.new(app, ['sticky']).call(request).last
    body.should.equal ['<html><a href="/">Root</a></html>']
  end

  context 'more than one sticky' do

    specify "should append all sticky params" do
      app_body = '<html><a href="/">Root</a></html>'
      app = lambda { |env| [200, {'Content-Type' => 'text/html'}, [app_body]] }
      request = Rack::MockRequest.env_for("/", :params => "one=1&two=2")
      body = Rack::StickyParams.new(app, ['one', 'two']).call(request).last
      body.should.equal ['<html><a href="/?one=1&two=2">Root</a></html>']
    end

  end

  context 'non-successul response' do 

    specify "should not append on non successful status" do
      app_body = '<html><a href="/">Root</a></html>'
      app = lambda { |env| [500, {'Content-Type' => 'text/html'}, [app_body]] }
      request = Rack::MockRequest.env_for("/", :params => "sticky=there")
      body = Rack::StickyParams.new(app, ['sticky']).call(request).last
      body.should.equal ['<html><a href="/">Root</a></html>']
    end
  end

  context 'no external links' do 
    specify "should not append on non successful status" do
      app_body = '<html><a href="http://www.google.de">Root</a></html>'
      app = lambda { |env| [200, {'Content-Type' => 'text/html'}, [app_body]] }
      request = Rack::MockRequest.env_for("/", :params => "sticky=there")
      body = Rack::StickyParams.new(app, ['sticky']).call(request).last
      body.should.equal ['<html><a href="http://www.google.de">Root</a></html>']
    end
  end

  context 'mime types' do

    specify "it does not work on other mime types by default" do
      app_body = '<html><a href="/">Root</a></html>'
      app = lambda { |env| [200, {'Content-Type' => 'application/json'}, [app_body]] }
      request = Rack::MockRequest.env_for("/", :params => "sticky=there")
      body = Rack::StickyParams.new(app, ['sticky']).call(request).last
      body.should.equal ['<html><a href="/">Root</a></html>']
    end

    specify "it does work on other mime types if specified" do
      app_body = '<html><a href="/">Root</a></html>'
      app = lambda { |env| [200, {'Content-Type' => 'application/json'}, [app_body]] }
      request = Rack::MockRequest.env_for("/", :params => "sticky=there")
      body = Rack::StickyParams.new(app, ['sticky'], ['application/json']).call(request).last
      body.should.equal ['<html><a href="/?sticky=there">Root</a></html>']
    end

  end





end

