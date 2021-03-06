#
# Publish approved minutes on the public web site
#

require 'date'
require 'whimsy/asf/svn'

CONTENT = 'asf/infrastructure/site/trunk/content'
BOARD_SITE = ASF::SVN["#{CONTENT}/foundation/board"]
MINUTES = ASF::SVN["#{CONTENT}/foundation/records/minutes"]
BOARD_PRIVATE = ASF::SVN['private/foundation/board']
CALENDAR = "#{BOARD_SITE}/calendar.mdtext"

# update from svn
[MINUTES, BOARD_SITE, BOARD_PRIVATE].each do |dir| 
  Dir.chdir(dir) {`svn cleanup`; `svn up`}
end

calendar = File.read(CALENDAR)

# clean up summary
@summary = @summary.gsub(/\r\n/,"\n").sub(/\s+\Z/,'') + "\n"

# extract date and year from minutes
@date.untaint if @date =~ /^\d+_\d+_\d+$/
date = Date.parse(@date.gsub('_', '-'))
year = date.year
fdate = date.strftime("%d %B %Y")

# add year header
unless calendar.include? "##{year}"
  calendar[/^()#.*Board meeting minutes #/,1] =
    "# #{year} Board meeting minutes # {##{year}}\n\n"
end

# add summary
if calendar.include? "\n- [#{fdate}]"
  calendar.sub! /\n-\s+\[#{fdate}\].*?(\n[-#])/m, "\n" + @summary + '\1'
else
  calendar[/# #{year} Board meeting minutes #.*\n()/,1] = "\n" + @summary
end

# remove from calendar
calendar.sub! /^(\s*-\s+#{fdate}\s*\n)/, ''

#Commit the Minutes
Dir.chdir MINUTES do
  unless Dir.exist? year.to_s
    _.system "mkdir #{year}"
    _.system "svn add #{year}"
  end

  if not File.exist? "#{year}/board_minutes_#{@date}.txt"
    _.system "cp #{BOARD_PRIVATE}/board_minutes_#{@date}.txt #{year}"
    _.system "svn add #{year}/board_minutes_#{@date}.txt"

    _.system [
      'svn', 'commit', '-m', @message, year.to_s,
      ['--no-auth-cache', '--non-interactive'],
      (['--username', env.user, '--password', env.password] if env.password)
    ]

    File.unlink 'svn-commit.tmp' if File.exist? 'svn-commit.tmp'

    unless `svn st`.empty?
      raise "svn failure #{MINUTES}"
    end
  end
end

# Update the Calendar
Dir.chdir BOARD_SITE do
  if File.read(CALENDAR) != calendar
    File.open(CALENDAR, 'w') {|fh| fh.write calendar}

    _.system [
      'svn', 'commit', '-m', @message, File.basename(CALENDAR),
      ['--no-auth-cache', '--non-interactive'],
      (['--username', env.user, '--password', env.password] if env.password)
    ]

    unless `svn st`.empty?
      raise "svn failure #{BOARD_SITE}"
    end
  end
end

# Clean up board directory
Dir.chdir BOARD_PRIVATE do
  updated = false

  if File.exist? "board_minutes_#{@date}.txt"
    _.system "svn rm board_minutes_#{@date}.txt"
    updated = true
  end
  
  if File.exist? "board_agenda_#{@date}.txt"
    _.system "svn mv board_agenda_#{@date}.txt archived_agendas"
    updated = true
  end

  if updated
    _.system [
      'svn', 'commit', '-m', @message,
      ['--no-auth-cache', '--non-interactive'],
      (['--username', env.user, '--password', env.password] if env.password)
    ]

    unless `svn st`.empty?
      raise "svn failure: #{BOARD_PRIVATE}"
    end
  end
end

Dir.chdir(BOARD_PRIVATE) {Dir['board_minutes_*.txt'].sort}
