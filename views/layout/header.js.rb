#
# Header: title on the left, dropdowns on the right
#
# Also keeps the window/tab title in sync with the header title
#
# Finally: make info dropdown status 'sticky'

class Header < React
  def initialize
    @infodropdown = nil
  end

  def render
    _header.navbar.navbar_fixed_top class: @@item.color do
      _div.navbar_brand @@item.title

      _span.clock! "\u231B" if clock_counter > 0

      _ul.nav.nav_pills.navbar_right do

        # pending count
        if Pending.count > 0
          _li.label.label_danger do
            _Link text: Pending.count, href: 'queue'
          end
        end

        # 'info'/'online' dropdown
        #
        if @@item.attach
          _li.dropdown class: @infodropdown do
            _a.dropdown_toggle.info! onClick: self.toggleInfo do
              _ 'info'
              _b.caret
            end

            _dl.dropdown_menu.dl_horizontal do
              _dt 'Attach'
              _dd @@item.attach

              if @@item.owner
                _dt 'Author'
                _dd @@item.owner
              end

              if @@item.shepherd
                _dt 'Shepherd'
                _dd @@item.shepherd
              end

              if @@item.flagged_by and not @@item.flagged_by.empty?
                _dt 'Flagged By'
                _dd @@item.flagged_by.join(', ')
              end

              if @@item.approved and not @@item.approved.empty?
                _dt 'Approved By'
                _dd @@item.approved.join(', ')
              end

              if @@item.roster or @@item.prior_reports or @@item.stats
                _dt 'Links'

                if @@item.roster
                  _dd { _a 'Roster', href: @@item.roster }
                end

                if @@item.prior_reports
                  _dd { _a 'Prior Reports', href: @@item.prior_reports }
                end

                if @@item.stats
                  _dd { _a 'Statistics', href: @@item.stats }
                end
              end
            end
          end

        elsif @@item.online
          _li.dropdown do
            _a.dropdown_toggle.info! data_toggle: "dropdown" do
              _ 'online'
              _b.caret
            end

            _ul.online.dropdown_menu @@item.online do |id|
              _li do
                _a id, href: "https://whimsy.apache.org/roster/committer/#{id}"
              end
            end
          end

        else
          _li.dropdown do
            _a.dropdown_toggle.info! data_toggle: "dropdown" do
              _ 'summary'
              _b.caret
            end

            summary = @@item.summary || Agenda.summary

            _table.table_bordered.online.dropdown_menu do
              summary.each do |status|
                text = status.text
                text.sub!(/s$/, '') if status.count == 1
                _tr class: status.color do
                  _td {_Link text: status.count, href: status.href}
                  _td {_Link text: text, href: status.href}
                end
              end
            end
          end
        end

        # 'navigation' dropdown
        #
        _li.dropdown do
          _a.dropdown_toggle.nav! data_toggle: "dropdown" do
            _ 'navigation'
            _b.caret
          end

          _ul.dropdown_menu do
            _li { _Link.agenda! text: 'Agenda', href: '.' }

            Agenda.index.each do |item|
              _li { _Link text: item.index, href: item.href } if item.index
            end

            _li.divider

            _li { _Link text: 'Search', href: 'search' }
            _li { _Link text: 'Comments', href: 'comments' }

            shepherd = Agenda.shepherd
            if shepherd
              _li do 
                _Link.shepherd! text: 'Shepherd', href: "shepherd/#{shepherd}"
              end
            end

            _li { _Link.queue! text: 'Queue', href: 'queue' }

            _li.divider

            _li { _Link.backchannel! text: 'Backchannel', href: 'backchannel' }

            _li { _Link.help! text: 'Help', href: 'help' }
          end
        end

      end
    end
  end

  # set title on initial rendering
  def componentDidMount()
    self.componentDidUpdate()
  end

  # update title to match the item title whenever page changes
  def componentDidUpdate()
    title = ~'title'
    if title.textContent != @@item.title
      title.textContent = @@item.title
    end
  end

  # toggle info dropdown
  def toggleInfo
    @infodropdown = (@infodropdown ? nil : 'open')
  end
end
