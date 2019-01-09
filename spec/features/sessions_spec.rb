require 'rails_helper'

RSpec.feature "Sessions", type: :feature do
  scenario 'As a visitor I want to see login options' do
    visit root_path
    click_link 'Prihlásiť'

    expect(page).to have_selector(:link_or_button, 'Odoslať prihlasovacie údaje na email')
    expect(page).to have_text('Prihlásiť sa pomocou Google')
  end

  scenario 'As a visitor I want to be able to login using magic link' do
    OmniAuth.config.test_mode = false

    default_url_options[:host] = "localhost:3000"

    visit root_path
    click_link 'Prihlásiť'

    within 'form' do
      fill_in :email, with: 'foo@bar.com'
    end

    expect(ActionMailer::Base.deliveries).to be_empty

    click_on 'Odoslať prihlasovacie údaje na email'

    expect(ActionMailer::Base.deliveries.size).to eq 1

    mailer_email = ActionMailer::Base.deliveries.first
    email = Capybara::Node::Simple.new(mailer_email.body.to_s)
    magic_link = email.find('a')[:href]

    expect(magic_link).to match(auth_callback_url(:magiclink))

    expect(page).not_to have_link('Odhlásiť')

    visit magic_link

    within '.user-info' do
      expect(page).to have_text('foo@bar.com')
      expect(page).to have_link('Odhlásiť')
    end
  end

  scenario 'As a visitor I want to be able to login using google' do
    OmniAuth.config.test_mode = true
    OmniAuth.config.add_mock(:google_oauth2, {
      provider: 'google_oauth2',
      info: {
        email: 'foo@bar.com'
      }
    })

    visit root_path
    click_link 'Prihlásiť'
    click_link 'Prihlásiť sa pomocou Google'

    within '.user-info' do
      expect(page).to have_text('foo@bar.com')
      expect(page).to have_link('Odhlásiť')
    end
  end
end
