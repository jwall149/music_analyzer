require "ruby-audio"
require "redis"
require './fourier_transform.rb'

@redis = Redis.new(:host => "localhost", :port => 6379)

fname = ARGV[0]

begin
    buf = RubyAudio::Buffer.short(WINDOW)
    RubyAudio::Sound.open(fname) do |snd|
        while snd.read(buf) != 0
            continue if buf.nil? || buf.to_a.empty?
            vector = FourierTransform.vector(buf.to_a,4)
            if vector[0]+vector[1]+vector[2]+vector[3] > 10
                @redis.set(vector.join('_'), fname)
                puts "#{vector.join('_')}"
            end
        end
    end
rescue
    puts "Error"
    exit
end
