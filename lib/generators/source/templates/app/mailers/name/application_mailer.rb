module <%= name.camelcase %>
  class ApplicationMailer < ActionMailer::Base
    default from: '<%= name.underscore %>-source@glancr.de'
    layout 'mailer'
  end
end
