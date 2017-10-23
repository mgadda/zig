#!/usr/bin/env ruby
require 'msgpack'


object_path = File.join('.zig', 'objects', ARGV[0].slice(0,2), ARGV[0].slice(2, ARGV[0].length - 1))
# objects = Dir.glob(object_glob).select { |fn| File.file?(fn) }
data = File.open(object_path).read
puts MessagePack.unpack(data)
