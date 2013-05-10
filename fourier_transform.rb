require "fftw3"
require 'pry'
WINDOW = 4096
RANGES = [[40,40],[80,40],[120,60],[180,120]]

class FourierTransform
  def self.fft(input, format = nil)
    reduce_bitrate = (8 if format && format > 258) || 0
    input = input.map{|i| i >> reduce_bitrate }
    na = NArray.to_na(input)
    fft_slice = (FFTW3.fft(na)/na.length*10).to_a[0, WINDOW/2]
    return fft_slice.map{|c| Math.sqrt(c.real ** 2 + c.imag ** 2).to_i }
  end

  def self.vector(input, format = nil)
    spectrum = FourierTransform.fft(input, format)
    vec = []
    RANGES.each do |range|
      vec << spectrum[range.first,range.last].max
    end
    vec
  end
end 