#
# Replacement for 'a' element which handles clicks events by calling
# Main.navigate.
#

class Link < React
  def initialize
    @attrs = {}
  end

  def componentWillMount()
    self.componentWillReceiveProps(self.props)
    @attrs.onClick = self.click
  end

  def componentWillReceiveProps(props)
    @text = props.text
    for attr in props
      @attrs[attr] = props[attr] unless attr == 'text'
    end
  end

  def render
    React.createElement('a', @attrs, @text)
  end

  def click(event)
    href = event.target.getAttribute('href')
    unless href.start_with? '.'
      Main.navigate href
      return false
    end
  end
end