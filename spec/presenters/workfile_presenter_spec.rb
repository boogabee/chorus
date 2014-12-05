require 'spec_helper'

describe WorkfilePresenter, :type => :view do
  let(:user) { users(:owner) }
  let(:workfile) { workfiles(:private) }
  let(:workspace) { workfile.workspace }
  let(:options) { {} }
  let(:presenter) { WorkfilePresenter.new(workfile, view, options) }

  before(:each) do
    set_current_user(user)
  end

  describe "#to_hash" do
    let(:hash) { presenter.to_hash }

    it "includes the right keys" do
      hash.should have_key(:workspace)
      hash.should have_key(:owner)

      hash.should have_key(:file_name)
      hash.should have_key(:file_type)
      hash.should have_key(:is_deleted)
      hash.should have_key(:recent_comments)
      hash.should have_key(:comment_count)
      hash.should have_key(:tags)
      hash.should have_key(:user_modified_at)
      hash.should have_key(:status)
    end

    it "uses the workspace presenter to serialize the workspace" do
      hash[:workspace].to_hash.should == (WorkspacePresenter.new(workspace, view).presentation_hash)
    end

    it "the workspace presenter does not lose the succinct option" do
      options[:succinct] = true
      hash[:workspace].to_hash.should == (WorkspacePresenter.new(workspace, view, :succinct => true).presentation_hash)
    end

    it "uses the succinct user presenter to serialize the owner" do
      hash[:owner].to_hash.should == (UserPresenter.new(user, view, :succinct => true).presentation_hash)
    end

    it "uses the workfile file name" do
      hash[:file_name].should == workfile.file_name
    end

    it "includes entity_subtype" do
      stub(workfile).entity_subtype { 'something' }
      hash[:entity_subtype].should == 'something'
    end

    context "when presenting for a list" do
      let(:options) { { :list_view => true }}
      it "uses the succinct workspace presenter" do
        hash[:workspace].to_hash.should == (WorkspacePresenter.new(workspace, view, :succinct => true).presentation_hash)
      end
    end

    context "when the workfile has tags" do
      let(:workfile) { workfiles(:tagged) }

      it 'includes the tags' do
        hash[:tags].count.should be > 0
        hash[:tags].should == Presenter.present(workfile.tags, @view)
      end
    end

    context "when there are notes on a workfile" do
      let(:recent_comments) { hash[:recent_comments] }
      let(:today) { Time.current }
      let(:yesterday) { today - 1.day }

      before do
        workfile.events.clear
        Timecop.freeze yesterday do
          Events::NoteOnWorkfile.create!({:note_target => workfile, :body => 'note for yesterday'}, :as => :create)
        end
        Timecop.freeze today do
          Events::NoteOnWorkfile.create!({:workfile => workfile, :body => 'note for today'}, :as => :create)
        end
        workfile.reload
      end

      it "presents the notes as comments in reverse timestamp order" do
        recent_comments[0][:author].to_hash.should == Presenter.present(user, view, {:succinct => true, :activity_stream => true})
        recent_comments[0][:body].should == "note for today"
        recent_comments[0][:timestamp].to_i.should == today.to_i
      end

      it "presents only the last comment" do
        recent_comments.count.should == 1
      end

      it "includes the comment count" do
        hash[:comment_count].should == 2
      end

      context "when there is a comment on a note" do
        let(:comment_timestamp) { today + 2.hours }

        before do
          Timecop.freeze comment_timestamp do
            last_note = workfile.events.last
            FactoryGirl.create :comment, :event => last_note, :body => "comment on yesterday's note", :author => user
          end
        end

        context "when the comment is newer than the notes" do
          it "presents the comment before the notes" do
            recent_comments[0][:author].to_hash.should == Presenter.present(user, view, :succinct => true)
            recent_comments[0][:body].should == "comment on yesterday's note"
            recent_comments[0][:timestamp].to_i.should == comment_timestamp.to_i
          end
        end

        context "when the comment is older than the newest note" do
          let(:comment_timestamp) { today - 2.hours }

          it "presents the comment after the newset note" do
            recent_comments[0][:body].should == "note for today"
          end
        end

        it "includes the comment in the comment count" do
          hash[:comment_count].should == 3
        end
      end
    end

    context "for activity stream" do
      let(:options) { {:activity_stream => true} }

      it "should not include owner or draft status" do
        hash[:owner].should be_nil
        hash[:has_draft].should be_nil
      end
    end

    describe "complete_json?" do
      context "when rendering activity stream" do
        let(:options) { {:activity_stream => true} }
        it "should be false" do
          presenter.should_not be_complete_json
        end
      end

      context "when not rendering for activity stream" do
        let(:options) { {:activity_stream => false} }
        it "is true" do
          presenter.complete_json?.should be_true
        end
      end
    end
  end
end
