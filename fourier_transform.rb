require "fftw3"
WINDOW = 1024

class FourierTransform
  def self.fft(input)
    na = NArray.to_na(input)
    fft_slice = FFTW3.fft(na).to_a[0, WINDOW/2]
    return fft_slice.map{|c| Math.sqrt(c.real ** 2 + c.imag ** 2).to_i }
  end

  def self.vector(input, dim)
    spectrum = FourierTransform.fft(input)
    vec = []
    spectrum.each_slice(WINDOW/dim/2) { |slice| vec << slice.max }
    vec[0] = vec[0] >> 16
    vec[1] = vec[1] >> 12
    vec[2] = vec[2] >> 10
    vec[3] = vec[3] >> 8
    vec
  end
end 