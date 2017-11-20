ENV['RACK_ENV'] = 'test'
require 'rack/test'
require_relative '../app/service'

include Rack::Test::Methods
def app() Sinatra::Application end
