#
# Display information associated with an agenda item:
#   - special notes
#   - posted reports
#   - posted comments
#   - pending comments
#   - action items
#   - minutes
#
# Note: if AdditionalInfo is included multiple times in a page, set
#       prefix to true (or a string) to ensure rendered id attributes
#       are unique.
#

class AdditionalInfo < React
  def render
    # special notes
    _p.notes @@item.notes if @@item.notes

    # posted reports
    if @@item.missing
      posted = Posted.get(@@item.title)
      unless posted.empty?
        _h4 'Posted reports', id: "#{@prefix}posted"
        _ul posted do |post|
          _li do
            _a post.subject, href: post.link
          end
        end
      end
    end

    # posted comments
    unless @@item.comments.empty?
      _h4 'Comments', id: "#{@prefix}comments"
      @@item.comments.each do |comment|
        _pre.comment do
          _Text raw: comment, filters: [hotlink]
        end
      end
    end

    # pending comments
    if @@item.pending
      _h4 'Pending Comment', id: "#{@prefix}pending"
      _pre.comment Flow.comment(@@item.pending, Pending.initials)
    end

    # action items
    if @@item.title != 'Action Items' and not @@item.actions.empty?
      _h4 id: "#{@prefix}actions" do
        _Link text: 'Action Items', href: 'Action-Items'
      end
      _ActionItems item: @@item, filter: {pmc: @@item.title}
    end

    # minutes
    minutes = Minutes.get(@@item.title)
    if minutes
      _h4 'Minutes', id: "#{@prefix}minutes"
      _pre.comment minutes
    end
  end

  # ensure componentWillReceiveProps is called on before first rendering
  def componentWillMount()
    self.componentWillReceiveProps()
  end

  # determine prefix (if any)
  def componentWillReceiveProps()
    if @@prefix == true
      @prefix = @@item.title.downcase() + '-'
    elsif @@prefix
      @prefix = @@prefix
    else
      @prefix = ''
    end
  end
end
