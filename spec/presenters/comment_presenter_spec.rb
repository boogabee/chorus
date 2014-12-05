require 'spec_helper'

describe CommentPresenter, :type => :view do
  let(:comment) { comments(:comment_on_note_on_greenplum) }
  let(:presenter) { CommentPresenter.new(comment, view) }

  describe "#to_hash" do
    let(:hash) { presenter.to_hash }

    it "includes the right keys" do
      hash.should have_key(:id)
      hash.should have_key(:author)
      hash.should have_key(:body)
      hash.should have_key(:timestamp)
    end

    it "presents a succinct author" do
      hash[:author].to_hash.should == (UserPresenter.new(comment.author, view, :succinct => true).presentation_hash)
    end

    context "when the author is deleted" do
      before do
        comment.author = users(:not_a_member)
        comment.author.destroy
        comment.reload
      end

      it "presents an author" do
        hash[:author].should_not be_nil
      end
    end

    context 'with evil html in the body' do
      before do
        comment.update_attributes(:body => '<b>good</b><script>evil</script>')
      end

      it 'sanitizes the body' do
        hash[:body].should == '<b>good</b>'
      end
    end
  end
end