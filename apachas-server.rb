$: << '.'

require 'sinatra'
require 'haml'
require 'lib/apachas'

get '/' do
    haml :index
end

post '/' do
    data = params[:data]#.strip
    #data.inspect
    begin
        @gastos = Apachas.procesa(data)
        haml :gastos
    rescue Exception => e
        @error_message = e.message
        haml :error
    end
end
