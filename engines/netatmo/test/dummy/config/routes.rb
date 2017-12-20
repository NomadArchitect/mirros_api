Rails.application.routes.draw do
  mount Netatmo::Engine => "/netatmo"
end
