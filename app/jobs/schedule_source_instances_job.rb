# One-time job on startup to schedule all existing SourceInstance models.
class ScheduleSourceInstancesJob < ApplicationJob
  queue_as :sources

  def perform(*args)
    SourceInstance.all.each do |si|
      RefreshSourceInstanceJob.perform_now si.id
      si.schedule unless si.scheduled?
    end
  end
end
