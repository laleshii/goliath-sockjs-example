require 'goliath'
require 'goliath/websocket'
require 'goliath/rack/templates'

require 'faye'
Faye::WebSocket.load_adapter('goliath')


class EchoExtension
  def incoming(message, callback)
    p message
    unless message['channel'] == '/ping'
      return callback.call(message)
    end

    faye_client.publish('/pong', message['data'])
    
    callback.call(message)
  end

  def faye_client
    @faye_client ||= Faye::Client.new('http://localhost:3000/ws')
  end
end


class Websocket < Goliath::API
  
  use Goliath::Rack::Favicon, File.expand_path(File.dirname(__FILE__) + '/ws/favicon.ico')

  use( Rack::Static,
    :root => Goliath::Application.app_path('ws'),
    :urls => ['/index.html','/faye-browser-min.js'],
    :cache_control => 'public, max-age=3600'
  )

  use Faye::RackAdapter, :mount      => '/ws',
                         :timeout    => 25,
                         :extensions => EchoExtension.new

  include Goliath::Rack::Templates

  def response(env)
    [200, {'Content-Type' => 'text/html'}, '<meta http-equiv="refresh" content="0;URL=\'/index.html\'">']
  end
end