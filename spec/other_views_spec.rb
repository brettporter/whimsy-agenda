#
# Other views
#

require_relative 'spec_helper'

feature 'other reports' do
  it "should support search" do
    visit '/2015-02-18/search?q=ruby'

    expect(page).to have_selector 'pre', text: 'Sam Ruby'
    expect(page).to have_selector 'h4 a', text: 'Qpid'
  end

  it "should support comments" do
    visit '/2015-01-21/comments'

    # unseen items
    expect(page).to have_selector 'h4 a', text: 'Curator'
    expect(page).to have_selector 'pre', 
      text: /last PMC member and committer additions/

    # seen items
    expect(page).not_to have_selector 'h4 a', text: 'ACE'
    expect(page).not_to have_selector 'pre', text: /Reminder email sent/

    # footer
    expect(page).to have_selector 'button', text: 'mark seen'
    expect(page).to have_selector 'button', text: 'show seen'
  end

  it "should support queued/pending approvals and comments" do
    visit '/2015-02-18/queue'

    expect(page).to have_selector :xpath, 
      '//p[1]/a[@href="queue/W3C-Relations"]', text: 'W3C Relations'
    expect(page).to have_selector :xpath,
      '//p[2]/a[@href="Security-Team"]', text: 'Security Team'
    expect(page).to have_selector :xpath,
      '//p[3]/a[@href="Axis"]', text: 'Axis'
    expect(page).to have_selector :xpath,
      '//p[4]/a[@href="queue/Celix"]', text: 'Celix'
    expect(page).to have_selector 'a.default', text: 'January 21, 2015'
    expect(page).to have_selector 'dt a[href="BookKeeper"]', text: 'BookKeeper'
    expect(page).to have_selector 'dd p', text: 'Nice report!'
    expect(page).to have_selector 'li', 
      text: 'follow up with PMC for clarification'

    expect(page).to have_selector '#commit-text', text: 
      ['Approve W3C Relations', 'Unapprove Security Team', 'Flag Axis',
        'Comment on BookKeeper',
        'Update AI: follow up with PMC for clarification'].join(' ')
  end

  it "should follow the ready queue" do
    visit '/2015-01-21/queue/Onami'

    expect(page).to have_selector '.navbar-fixed-top.reviewed .navbar-brand', 
      text: 'Onami'

    expect(page).to have_selector '.backlink[href="queue/MyFaces"]',
      text: 'MyFaces'
    expect(page).to have_selector '.nextlink[href="queue/OpenOffice"]',
      text: 'OpenOffice'
  end

  it "should show shepherd reports" do
    visit '/2015-01-21/shepherd/Sam'

    # action items
    expect(page).to have_selector 'pre.report span', 
      text: '* Sam: pursue a report for Abdera'
    expect(page).to have_selector 'pre.report em', 
      text: "Clarification provided in this month's report."

    # committee reports
    expect(page).to have_selector 'h3.reviewed a[href="shepherd/queue/Flink"]',
      text: 'Flink'
    expect(page).to have_selector 'a.default', text: 'Airavata'
    expect(page).to have_selector 'h4', text: 'Comments'
    expect(page).to have_selector 'pre.comment span', 
      text: 'cm: great report!'
    expect(page).to have_selector 'h4', text: 'Action Items'
    expect(page).to have_selector 'pre.report span', 
      text: '* Chris: Please clarify what "voted on" means'
    expect(page).to have_selector 'button[data-attach=AY]', text: 'flag'
    expect(page).to have_selector '.shepherd button', text: 'send email'

    # prefixed sections
    expect(page).to have_selector '#flink-comments', text: 'Comments'
    expect(page).to have_selector '#james-actions', text: 'Action Items'
    expect(page).to have_selector '#rave-minutes', text: 'Minutes'

    expect(page).to have_selector '.backlink[href="shepherd/Ross"]',
      text: 'Ross'
    expect(page).not_to have_selector '.nextlink'
  end

  it "should follow the shepherd queue" do
    visit '/2015-02-18/shepherd/queue/Hama'

    expect(page).to have_selector '.navbar-fixed-top.missing .navbar-brand', 
      text: 'Hama'

    expect(page).to have_selector '.backlink[href="shepherd/queue/Forrest"]',
      text: 'Forrest'
    expect(page).to have_selector '.nextlink[href="shepherd/queue/Mesos"]',
      text: 'Mesos'
  end

  it "should highlight and crosslink action items" do
    visit '/2015-01-21/Action-Items'

    expect(page).to have_selector 'span.missing', text: /^\s*Status:$/
    expect(page).to have_selector 'a.missing[href=DirectMemory]',
      text: 'DirectMemory'
    expect(page).to have_selector 'em',
      text: "Clarification provided in this month's report."
    expect(page).to have_selector 'a.reviewed[href=Isis]', text: 'Isis'
    expect(page).to have_selector '.backlink[href="Discussion-Items"]',
      text: 'Discussion Items'
    expect(page).to have_selector '.nextlink[href="Unfinished-Business"]',
      text: 'Unfinished Business'
    expect(page).to have_selector 'h3', 
      text: 'Action Items Captured During the Meeting'

    expect(page).to have_selector 'a[href="http://example.com"]'
    expect(page).to have_selector 'span', 
      text: '* Sam: Is the project ready for retirement?'
    expect(page).to have_selector 'a.missing[href=JMeter]', text: 'JMeter'
    expect(page).to have_selector 'span', text: '2015-01-21 ]'
  end

  it "should draft action items" do
    visit '/2015-02-18/Action-Items'
    expect(page).to have_selector 'p.alert-info', 
      text: 'Action Items have yet to be posted'
    expect(page).to have_selector 'button.btn-primary', text: 'post actions'
  end

  it "should show flagged items" do
    visit '/2015-02-18/flagged'
    
    expect(page).to have_selector 'h3 a', text: 'Axis'
    expect(page).to have_selector 'h4', text: 'Comments'
    expect(page).to have_selector 'pre span', text: 'jj: Reminder email sent'
    expect(page).to have_selector 'h4', text: 'Minutes'
    expect(page).to have_selector 'pre', text: '@Sam: follow up with Axis PMC.'

    expect(page).to have_selector 'h3 a', text: 'Lenya'
  end

  it "should show missing items" do
    visit '/2015-02-18/missing'
    
    expect(page).to have_selector 'h3 a', text: 'Cassandra'
    expect(page).to have_selector 'h4', text: 'Comments'
    expect(page).to have_selector 'pre span', text: 'cm: Reminder email sent'
    expect(page).to have_selector 'h4', text: 'Minutes'
    expect(page).to have_selector 'pre', 
      text: '@Sam: Is anyone on the PMC looking at the reminders?'

    # reminders
    expect(page).to have_selector 'input[type=checkbox][name=selected]' + 
      '[value=Airavata]'
    expect(page).to have_selector 'button.btn-primary',
      text: 'send initial reminders'
    expect(page).to have_selector 'button.btn-primary',
      text: 'send final reminders'
  end

  it "should hypertext minutes" do
    visit '/2015-02-18/January-21-2015'

    expect(page).to have_selector \
     'a[href="https://svn.apache.org/repos/private/foundation/board/board_minutes_2015_01_21.txt"]',
     text: 'board_minutes_2015_01_21.txt'
  end

  it "should show a help page" do
    visit '/2015-02-18/help'

    # navigation
    expect(page).to have_selector '#agenda', text: 'Agenda'
    expect(page).to have_selector '#queue', text: 'Queue'
    expect(page).to have_selector '#help', text: 'Help'
    expect(page).to have_selector '#nav', text: 'navigation'

    # body
    expect(page).to have_selector 'dt', text: 'right arrow'
    expect(page).to have_selector 'dd', text: 'next page'
  end
end
