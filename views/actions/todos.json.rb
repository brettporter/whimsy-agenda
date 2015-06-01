#
# Secretary post-meeting todo list
#

agenda = "board_agenda_#{params[:date].gsub('-', '_')}.txt"
agenda.untaint if params[:date] =~ /^\d+-\d+\d+/
parsed = Agenda.parse(agenda, :full)

transitioning = {}
establish = {}
terminate = {}

parsed.each do |item|
  next unless item[:attach] =~ /^7\w$/
  if item['title'] =~ /^Change .*? Chair$/ and item['people']
    item['people'].keys.each do |person|
      transitioning[ASF::Person.find(person)] = item['title']
    end
  elsif item['title'] =~ /^Establish\s*(.*?)\s*$/ and item['chair']
    establish[$1] = item['title']
    transitioning[ASF::Person.find(item['chair'])] = item['title']
  elsif item['title'] =~ /^Terminate\s*(.*?)\s*$/
    terminate[$1] = item['title']
  end
end

add = transitioning.keys - ASF.pmc_chairs
remove = ASF.pmc_chairs - ASF::Committee.list.map(&:chair) - transitioning.keys

_add add.map {|person| {id: person.id, name: person.public_name, 
  resolution: transitioning[person]}}.sort_by {|person| person[:id]}
_remove remove.map {|person| {id: person.id, name: person.public_name}}.
  sort_by {|person| person[:id]}
_establish establish.map {|name, resolution| {name: name, 
  resolution: resolution}}
_terminate terminate.map {|name, resolution| {name: name, 
  resolution: resolution}}