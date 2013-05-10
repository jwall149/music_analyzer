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
    wave = input.read_array_of_int8(frameCount)
    vector = FourierTransform.vector(wave)
    
    print "\e[2J\e[H"    
    puts "Songs:"
    @songs.sort_by {|k,v| v}.reverse
    @songs.keys[0,10].each do |song|
      puts "#{song} has #{@songs[song]} hit(s)!"
    end

    hits = @redis.get(vector.join("_"))
    puts vector.join("_").to_s

    if hits
      hits = Marshal.load(hits)
      hits.each do |hit|
        @songs[hit] = @songs[hit] ? @songs[hit] + 1  : 1
      end
    end
    
    @playing ? :paContinue : :paAbort
  end
end

API.Pa_Initialize

input = API::PaStreamParameters.new
input[:device] = API.Pa_GetDefaultInputDevice
input[:channelCount] = 1
input[:sampleFormat] = API::Int8
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