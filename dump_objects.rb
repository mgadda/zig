#!/usr/bin/env ruby
require 'msgpack'

object_glob = File.join('.zig', 'objects', '**', '*')
objects = Dir.glob(object_glob).select { |fn| File.file?(fn) }

objects.each do |path|
  data = File.open(path).read
  puts MessagePack.unpack(data)
end
