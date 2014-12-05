require 'spec_helper'

describe Upload do
  describe 'validations' do
    let(:max_hd_upload_size) {ChorusConfig.instance['file_sizes_mb']['hd_upload']}

    it { should have_attached_file(:contents) }
    it { should validate_attachment_presence(:contents) }
    it { should validate_attachment_size(:contents).less_than(max_hd_upload_size.megabytes) }
    it { should belong_to(:user) }
    it { should validate_presence_of(:user) }
  end

  it_behaves_like 'an upload that goes stale'
end
