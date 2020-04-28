class SwitchOwmCurrentWeatherSchema < ActiveRecord::Migration[5.2]
  def change
    gid = Group.find_by(slug: 'current_weather')
    return if gid.nil?

    Widget.find_by(slug: 'owm_current_weather')&.widget_instances&.each do |instance|
      instance.instance_associations.each do |ia|
        ia.group = gid
        ia.save!
      end
    end
  end
end
