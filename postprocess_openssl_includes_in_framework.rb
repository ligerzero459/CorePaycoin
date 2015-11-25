#!/usr/bin/env ruby

framework_path = ARGV[0] || "binaries/**/CorePaycoin.framework"

Dir.glob("#{framework_path}/**/*.h").each do |src|
  # puts "REWRITING INCLUDES IN #{src}"
  
  data = File.read(src)
  
  #include <openssl/bn.h> => #include <CorePaycoin/openssl/bn.h>
  data.gsub!(%r{#(include|import) <openssl/}, "#\\1 <CorePaycoin/openssl/")
  
  #import "XPYSignatureHashType.h" => #import <CorePaycoin/XPYSignatureHashType.h> 
  data.gsub!(%r{#(include|import) "(XPY.*?\.h)"}, "#\\1 <CorePaycoin/\\2>")
  
  File.open(src, "w"){|f| f.write(data)}
end
