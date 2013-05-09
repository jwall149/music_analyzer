require 'ffi-portaudio'
require 'redis'
require './fourier_transform.rb'

include FFI::PortAudio

class FFTStream < Stream
  def initialize
    @max = 1
    @playing = true
    @redis = Redis.new(:host => "localhost", :port => 6379)
    @songs = {}
  end

  def process(input, output, frameCount, timeInfo, statusFlags, userData)
    vector = FourierTransform.vector(input.read_array_of_int16(frameCount),4)
    
    print "\e[2J\e[H"
    puts "Songs:"

    val = @redis.get(vector.join("_"))    

    if val
      @songs[val] = @songs[val] ? @songs[val] + 1  : 1
      puts "#{val}: #{@songs[val]}"
    end
    
    @playing ? :paContinue : :paAbort
  end
end

API.Pa_Initialize

input = API::PaStreamParameters.new
input[:device] = API.Pa_GetDefaultInputDevice
input[:channelCount] = 1
input[:sampleFormat] = API::Int16
input[:suggestedLatency] = 0
input[:hostApiSpecificStreamInfo] = nil

playing = true
Signal.trap('INT') { 
  API.Pa_Terminate
  playing = false
  exit
}

stream = FFTStream.new
stream.open(input, nil, 44100, WINDOW)
stream.start

loop do
  sleep(1)
end

stream.close
API.Pa_Terminate