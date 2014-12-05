class JobResultsController < ApplicationController
  def show
    job = Job.find(params[:job_id])
    present job.job_results.last
  end
end