# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).

Setting.create(
  [
=begin
    {
      category: 'display',
      key: 'orientation',
      value: '1'
    },
    {
      category: 'display',
      key: 'offInterval',
      value: 'off'
    },
    {
      category: 'display',
      key: 'offIntervalStart',
      value: ''
    },
    {
      category: 'display',
      key: 'offIntervalEnd',
      value: ''
    },
=end
    {
      category: 'network',
      key: 'connectionType',
      value: 'wlan'
    },
    {
      category: 'network',
      key: 'ssid',
      value: ''
    },
    {
      category: 'network',
      key: 'ssidInvisible',
      value: 'no' # Requires frontend to specify checkbox values.
    },
    {
      category: 'network',
      key: 'password',
      value: ''
    },
    {
      category: 'system',
      key: 'language',
      value: '' # Settings SPA defaults to browser language until user chooses a language.

    },
    {
      category: 'personal',
      key: 'email',
      value: ''
    },
    {
      category: 'personal',
      key: 'name',
      value: ''
    },
    {
      category: 'personal',
      key: 'privacyConsent',
      value: 'no' # Requires frontend to specify checkbox values.
    }
  ]
)

Group.create(
  [
    {
      name: 'calendar'
    },
    {
      name: 'reminder_list'
    },
    {
      name: 'weather'
    },
    {
      name: 'news'
    },
    {
      name: 'public_transport'
    },
    {
      name: 'fuel'
    },
    {
      name: 'traffic'
    },
    {
      name: 'music_player'
    }
  ]
)
