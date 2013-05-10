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
            vector = FourierTransform.vector(buf.to_a, snd.info.format)
            puts "#{buf.to_a.max} #{buf.to_a.min}"
            if vector.reduce(:+) > 5
                songs = Marshal.load(@redis.get(vector.join('_')) || "\x04\b[\x00")
                unless songs.include?(fname)
                    songs << fname
                    @redis.set(vector.join('_'), Marshal.dump(songs))
                    puts "#{vector.join('_')}: #{songs}"
                end
            end
        end
    end
rescue => err
    puts "Error #{err.to_s}"
    exit
end
