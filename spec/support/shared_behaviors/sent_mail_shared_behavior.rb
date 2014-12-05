shared_examples 'a sent mail with subject and recipient' do

  it 'sends an email to the specified user with subject' do
    sent_mail.subject.should == subject
    sent_mail.to.should == [recipient.email]
  end

  it 'adds to the deliveries list' do
    expect do
      sent_mail
    end.to change(ActionMailer::Base.deliveries, :count).by(1)
  end
end
