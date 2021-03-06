#
# A two section representation of an agenda item (typically a PMC report),
# where the two sections will show up as two columns on wide enough windows.
#
# The first section contains the item text, with a missing indicator if
# the report isn't present.  It also contains an inline copy of draft
# minutes for agenda items in section 3.
#
# The second section contains posted comments, pending comments, and
# action items associated with this agenda item.
#
# Filters may be used to highlight or hypertext link portions of the text.
#

class Report < React
  def render
    _section.flexbox do
      _section do
        if @@item.warnings
          _ul.missing @@item.warnings do |warning|
            _li warning
          end
        end

        _pre.report do
          if @@item.text
            _Text raw: @@item.text, filters: @filters
          elsif @@item.missing
            _p {_em 'Missing'} 
          else
            _p {_em 'Empty'} 
          end
        end

        if (@@item.missing or @@item.comments) and @@item.mail_list
          _section.reminder do
            _Email item: @@item
          end
        end

        if @@item.minutes
          _pre.comment do
            _Text raw: @@item.minutes, filters: [hotlink]
          end
        end
      end

      _section do
        _AdditionalInfo item: @@item
      end
    end
  end

  # check for additional actions on initial render
  def componentWillMount()
    self.componentWillReceiveProps()
  end

  def componentWillReceiveProps()
    # determine what text filters to run
    @filters = [hotlink, self.privates, self.jira]
    @filters << self.localtime if @@item.title == 'Call to order'
    @filters << self.names if @@item.people
    @filters << self.president_attachments if @@item.title == 'President'

    # special processing for Minutes from previous meetings
    if @@item.attach =~ /^3[A-Z]$/
      @filters = [self.linkMinutes]

      # if draft is available, fetch minutes for display
      date = @@item.text[/board_minutes_(\d+_\d+_\d+)\.txt/, 1]

      if 
        date and not defined? @@item.minutes and defined? XMLHttpRequest and
        Server.drafts.include? "board_minutes_#{date}.txt"
      then
        @@item.minutes = ''
        fetch "minutes/#{date}", :text do |minutes|
          @@item.minutes = minutes
        end
      end
    end
  end

  #
  ### filters
  #

  # Convert start time to local time on Call to order page
  def localtime(text)
    return text.sub /\n(\s+)(Other Time Zones:.*)/ do |match, spaces, text|
      localtime = Date.new(@@item.timestamp).toLocaleString()
      "\n#{spaces}<span class='hilite'>" +
        "Local Time: #{localtime}</span>#{spaces}#{text}"
    end
  end

  # replace ids with committer links
  def names(text)
    roster = 'https://whimsy.apache.org/roster/committer/'

    for id in @@item.people
      person = @@item.people[id]

      # email addresses in 'Establish' resolutions and (ids) everywhere
      text.gsub! /(\(|&lt;)(#{id})( at |@|\))/ do |m, pre, id, post|
        if person.icla
          if post == ')' and person.member
            "#{pre}<b><a href='#{roster}#{id}'>#{id}</a></b>#{post}"
          else
            "#{pre}<a href='#{roster}#{id}'>#{id}</a>#{post}"
          end
        else
          "#{pre}<a class='missing' href='#{roster}?q=#{person.name}'>" +
            "#{id}</a>#{post}"
        end
      end

      # names
      if person.icla or @@item.title == 'Roll Call'
        pattern = escapeRegExp(person.name).gsub(/ +/, '\s+')
        if defined? person.member
          text.gsub! /#{pattern}/ do |match|
            "<a href='#{roster}#{id}'>#{match}</a>"
          end
        else
          text.gsub! /#{pattern}/ do |match| 
            "<a href='#{roster}?q=#{person.name}'>#{match}</a>"
          end
        end
      end

      # highlight potentially misspelled names
      if person.icla and not person.icla == person.name
        names = person.name.split(/\s+/)
        iclas = person.icla.split(/\s+/)
        ok = false
        ok ||= names.all? {|part| iclas.any? {|icla| icla.include? part}}
        ok ||= iclas.all? {|part| names.any? {|name| name.include? part}}
        if @@item.title =~ /^Establish/ and not ok
          text.gsub! /#{escapeRegExp("#{id}'>#{person.name}")}/,
            "?q=#{encodeURIComponent(person.name)}'>" +
            "<span class='commented'>#{person.name}</span>"
        else
          text.gsub! /#{escapeRegExp(person.name)}/, 
            "<a href='#{roster}#{id}'>#{person.name}</a>"
        end
      end

      # put members names in bold
      if person.member
        pattern = escapeRegExp(person.name).gsub(/ +/, '\s+')
        text.gsub!(/#{pattern}/) {|match| "<b>#{match}</b>"}
      end
    end

    # treat any unmatched names in Roll Call as misspelled
    if @@item.title == 'Roll Call'
      text.gsub! /(\n\s{4})([A-Z].*)/ do |match, space, name|
        "#{space}<a class='commented' href='#{roster}?q=#{name}'>#{name}</a>"
      end
    end

    # highlight mis-spelling of previous and proposed chair names
    if @@item.title.start_with? 'Change' and text =~ /\(\w[-_.\w]+\)/
      text.sub!(/heretofore\s+appointed\s+(\w(\s|.)*?)\s+\(/) do |text, name|
        text.sub(name, "<span class='hilite'>#{name}</span>")
      end

      text.sub!(/chosen\sto\s+recommend\s+(\w(\s|.)*?)\s+\(/) do |text, name|
        text.sub(name, "<span class='hilite'>#{name}</span>")
      end
    end

    return text
  end

  # link to board minutes
  def linkMinutes(text)
    text.gsub! /board_minutes_(\d+)_\d+_\d+\.txt/ do |match, year|
      if Server.drafts.include? match
        link = "https://svn.apache.org/repos/private/foundation/board/#{match}"
      else
        link = "http://apache.org/foundation/records/minutes/#{year}/#{match}"
      end
      "<a href='#{link}'>#{match}</a>"
    end

    return text
  end

  # private sections
  def privates(text)
    private_sections =
      Regexp.new('^([ \t]*&lt;private&gt;(?:\n|.)*?&lt;/private&gt;)(\s*)$',
      'mig')

    return text.gsub(private_sections, '<div class="private">$1</div>')
  end
  
  # expand president's attachments
  def president_attachments(text)
    match = text.match(/Additionally, please see Attachments (\d) through (\d)/)
    if match
      agenda = Agenda.index
      for i in 0...agenda.length
        next unless agenda[i].attach =~ /^\d$/
        if agenda[i].attach >= match[1] and agenda[i].attach <= match[2]
          text += "\n  #{agenda[i].attach}. " +
            "<a #{ agenda[i].text.empty? ? 'class="pres-missing" ' : ''}" +
            "href='#{agenda[i].href}'>#{agenda[i].title}</a>"
        end
      end
    end

    return text
  end

  # hotlink to JIRA issues
  def jira(text)
    jira_issue =
      Regexp.new(/(^|\s|\(|\[)([A-Z][A-Z0-9]+)-([1-9][0-9]*)
        (\.(\D|$)|[,;:\s)\]]|$)/x, 'g')

    text.gsub! jira_issue do |m, pre, name, issue, post|
      if JIRA.find(name)
        return "#{pre}<a target='_self' " +
          "href='https://issues.apache.org/jira/browse/#{name}-#{issue}'>" +
          "#{name}-#{issue}</a>#{post}"
      else
        return "#{pre}#{name}-#{issue}#{post}"
      end
    end

    return text
  end
end
