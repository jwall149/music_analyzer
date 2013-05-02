require 'ffi-portaudio'
require "fftw3"

include FFI::PortAudio

class Shazamlizator
  def initialize(window_size = nil)
    @window_size = window_size || 4096
  end

  def transform(input)
    na = NArray.to_na(input)
    fft_slice = FFTW3.fft(na).to_a[0, @window_size/2]
    return fft_slice
  end
end

class FFTStream < Stream

  attr_accessor :playing

  def initialize
    @max = 1
    @playing = true
  end

  def process(input, output, frameCount, timeInfo, statusFlags, userData)
    @fourier.fft input.read_array_of_int16(frameCount)
    
    print "\e[2J\e[H"
    puts "Spectrum"
    @fourier.spectrum[0, WINDOW/16].each_slice(2) do |a|
      sum = a.inject(0, :+)
      @max = [@max, sum].max
      s = "*" * (sum * 50 / @max).to_i

      [[0, 36], [5, 32], [40, 31]].reverse.each do |i, color|
        s[i] = "\e[#{color}m" if s[i]
      end
      puts s
      print "\e[0m"
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

stream = FFTStream.new
stream.open(input, nil, 44100, WINDOW)
stream.start

playing = true
Signal.trap('INT') { 
  playing = false
  stream.playing = false
}

loop do
  puts "stop" unless playing
  break unless playing
end

stream.close
API.Pa_Terminate
