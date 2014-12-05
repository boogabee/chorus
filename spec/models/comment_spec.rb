require "spec_helper"

describe Comment do
  it { should validate_presence_of :author_id }
  it { should validate_presence_of :body }
  it { should validate_presence_of :event_id }

  it_should_behave_like "recent"

  describe "search" do
    it "indexes text fields" do
      Comment.should have_searchable_field :body
    end

    describe "on a note" do
      let(:comment) { comments(:comment_on_note_on_greenplum) }
      let(:note) { comment.event }

      it "delegates grouping, type, and security fields the same as note" do
        comment.grouping_id.should == note.grouping_id
        comment.grouping_id.should_not be_blank
        comment.type_name.should == note.type_name
        comment.type_name.should_not be_blank
        comment.security_type_name.should == note.security_type_name
      end
    end
  end

  it_behaves_like 'a soft deletable model' do
    let(:model) { comments(:comment_on_note_on_greenplum)}
  end
end