require 'spec_helper'
require_relative 'helpers'

describe Events::JobDisabled do
  extend EventHelpers

  let(:job) { jobs(:default) }
  let(:workspace) { job.workspace }
  let(:actor) { job.owner }

  subject { described_class.by(actor).add(:job => job, :workspace => workspace) }

  it_creates_activities_for { [job, workspace] }
  it_does_not_create_a_global_activity
end
