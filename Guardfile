# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard :shell do
  watch %r{^lib/.+\.rb} do
   puts "restarting server"
   %x{pid=`ps ax | grep puma | head -1 | awk '{print $1}'`; kill -s USR2 $pid}
  end
end


