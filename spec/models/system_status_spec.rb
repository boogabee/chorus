require 'spec_helper'

describe SystemStatus do

  it { should ensure_length_of(:message).is_at_most(2048) }

end
