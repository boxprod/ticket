# Ticket

A feedback button for our Rails apps. The people using an app report a bug, an idea or a question, with a screenshot if they want, without a GitHub account. Each report becomes an issue in that app's repository.

- A small **Feedback** button in the corner of every page, for signed-in people only.
- They pick a kind, write what happened, and can capture the current tab, paste, drop or choose an image.
- The page, the browser, the app version, the Rails request id and the last JavaScript errors are sent with it.
- The report is saved in the app's database first, then a job files the issue. Nothing is lost if GitHub is down; a refused token marks the report `failed` with the reason.
- The issue links to the screenshot, which is served by the app behind its own sign-in.

The widget is a plain JavaScript custom element in a shadow root, served by the app's asset pipeline. It does not touch the app's JavaScript bundle, Stimulus, Tailwind or CSS. Its text is in French and English, following `I18n.locale`.

## Install in an app

```ruby
# Gemfile
gem "ticket"
```

Or `gem "ticket", github: "boxprod/ticket"` to follow `main` between releases.

```sh
bundle install
bin/rails ticket:install:migrations db:migrate
```

```ruby
# config/routes.rb
mount Ticket::Engine => "/ticket"
```

```ruby
# config/initializers/ticket.rb
Ticket.configure do |config|
  config.repository = "boxprod/the-app"
  config.github_token = Rails.application.credentials.dig(:ticket, :github_token)
  config.current_reporter = -> { Current.user }   # nil hides the button and refuses reports
end
```

```erb
<%# app/views/layouts/application.html.erb, at the end of <body> %>
<%= ticket_widget %>
```

Without a token, reports are kept in `ticket_reports` but not sent: that is what happens in development.

### Options

| Option | Default | |
|---|---|---|
| `repository` | — | `"owner/name"` |
| `github_token` | — | Fine-grained token with **Issues: read and write** on the repository |
| `current_reporter` | `-> { nil }` | Run in the controller and the view |
| `reporter_name` | `name`, then `email_address` | Gets the reporter, returns the name shown in the issue |
| `labels` | `["feedback"]` | The kind (`bug`, `idea`, `question`) is added |
| `parent_controller` | `"::ApplicationController"` | Its authentication applies to the engine |
| `app_version` | `KAMAL_VERSION` or `GIT_REVISION` | String or lambda |
| `max_screenshot_size` | 8 MB | |

### The GitHub token

Create a fine-grained personal access token (GitHub → Settings → Developer settings) with **boxprod** as its resource owner (the organization must allow fine-grained tokens: Settings → Personal access tokens), limited to the app's repository, with **Issues: read and write** and nothing else. Issues are opened in the name of the token's owner; the reporter's name is in the body. If GitHub refuses the labels, the issue is filed without them.

### Reports that were not sent

```sh
bin/rails ticket:redeliver
```

## Development

```sh
bundle install
bin/rails db:migrate
bin/rails test
CHROMIUM=/usr/bin/chromium bin/rails test:system   # the widget in headless Chromium, tab capture included
```

## Releasing

```sh
# bump lib/ticket/version.rb, commit, then:
git tag -a vX.Y.Z -m "X.Y.Z" && git push origin main vX.Y.Z
gem build ticket.gemspec && gem push ticket-X.Y.Z.gem   # asks for a one-time code
```
