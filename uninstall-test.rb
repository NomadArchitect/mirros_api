require 'tempfile'
require 'bundler'

gem = 'netatmo'
# bundler does not allow removal yet
search_text = /gem "#{gem}"/
tmp = Tempfile.new(['Gemfile.local', '.tmp'])
File.open('Gemfile.local', 'r') do |file|
  file.each_line do |line|
    tmp.write(line) unless line =~ search_text || line =~ /#/
  end
end
tmp.rewind

FileUtils.copy(tmp, 'Gemfile.local')
tmp.close!

cleaner = Bundler.load
cleaner.clean