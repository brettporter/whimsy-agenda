require_relative 'spec_helper'

feature 'item' do
  it "should show the Secretary report" do
    visit '/2014-02-19/Secretary'
    expect(page).to have_selector '.navbar-fixed-top .navbar-brand', 
      text: 'Secretary'
    expect(page).to have_selector 'pre', text: /December doldrums/
    expect(page).to have_selector '.backlink[href="Treasurer"]', 
     text: 'Treasurer'
    expect(page).to have_selector '.nextlink[href="Executive-Vice-President"]', 
     text: 'Executive Vice President'
  end
end