class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  after_save :set_refresh_flag

  def set_refresh_flag
    session_file = 'tmp/session.yml'
    data = YAML.load_file(session_file)
    data['refresh_frontend'] = true
    File.write(session_file, data.to_yaml)

  end
end
