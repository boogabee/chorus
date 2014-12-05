require 'spec_helper'
require_relative 'helpers'

describe Events::WorkFlowUpgradedVersion do
  extend EventHelpers

  let(:actor) { users(:owner) }
  let(:workfile) { workfiles(:public) }
  let(:workspace) { workfile.workspace }
  let(:commit_message) { 'hi!' }

  subject do
    Events::WorkFlowUpgradedVersion.add(
        :actor => actor,
        :workfile => workfile,
        :workspace => workspace,
        :commit_message => commit_message
    )
  end

  its(:targets) { should == {:workfile => workfile, :workspace => workspace} }

  it_creates_activities_for { [actor, workfile, workspace] }

  its(:commit_message) { should == commit_message }
end