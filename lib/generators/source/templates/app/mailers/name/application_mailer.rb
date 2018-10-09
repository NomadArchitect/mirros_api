module <%= name.camelcase %>
  class ApplicationMailer < ActionMailer::Base
    default from: '<%= name.downcase %>-source@glancr.de'
    layout 'mailer'
  end
end
