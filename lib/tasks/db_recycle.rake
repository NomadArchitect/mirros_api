# frozen_string_literal: true

namespace :db do
  desc 'Perform a clean db:drop/create/migrate/seed cycle'
  task recycle: :environment do
    Rake::Task['db:drop'].execute
    Rake::Task['db:create'].execute
    Rake::Task['db:migrate'].execute
    Rake::Task['db:seed'].execute
  end
end
