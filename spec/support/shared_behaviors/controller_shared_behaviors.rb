shared_examples_for "an action that requires authentication" do |method, action, params = {}|
  describe "when not authenticated" do
    before(:each) do
      log_out
    end

    it "returns unauthorized" do
      send(method, action, params)
      response.code.should == "401"
    end
  end
end

shared_examples_for "a paginated list" do
  let(:params) {{}}

  it "returns a paginated list" do
    send(:get, :index, params)
    response.code.should == '200'
    response.decoded_body.should have_key 'pagination'
    decoded_pagination.page.should == 1
  end
end

shared_examples_for :succinct_list do
  let(:params) { {:succinct => 'true'} }

  it "should present succinctly" do
    mock(Presenter).present(anything, anything, hash_including(:succinct => true))
    send(:get, :index, params)
  end
end

shared_examples_for "prefixed file downloads" do
  context "when file_download.name_prefix config option is set" do
    let(:prefix) { "123456789012345678901" }
    before do
      stub(ChorusConfig.instance).[]('file_download.name_prefix') { prefix }
      stub.proxy(ChorusConfig.instance).[](anything)
    end

    it "prefixes the filename correctly" do
      do_request
      response.headers["Content-Disposition"].should == "attachment; filename=\"#{prefix[0..19]}#{expected_filename}\""
    end
    
    context "when the prefix config option contains double quotes" do
      let(:prefix) { 'foo"bar"'}

      it "strips out double quotes" do
        do_request
        response.headers["Content-Disposition"].should == "attachment; filename=\"foobar#{expected_filename}\""
      end
    end

    context "when there is no prefix" do
      let(:prefix) { nil }

      it "returns the original filename" do
        do_request
        response.headers["Content-Disposition"].should == "attachment; filename=\"#{expected_filename}\""
      end
    end
  end

  context "when file_download.name_prefix is not set" do
    before do
      stub(ChorusConfig.instance).[]('file_download.name_prefix') { '' }
      stub.proxy(ChorusConfig.instance).[](anything)
    end

    it "does not prefix the filename" do
      do_request
      response.headers["Content-Disposition"].should == "attachment; filename=\"#{expected_filename}\""
    end
  end
end

shared_examples_for 'a protected demo mode controller' do |actions = [ :create, :update, :destroy ]|
  let(:params) {{}}

  before do
    stub(ChorusConfig.instance).demo_enabled? { true }
  end

  context 'as a non admin user' do
    let(:user) { users(:owner) }
    before { log_in user }

    if actions.include? :create
      it 'forbids create' do
        post :create, params
        response.code.should == '403'
      end
    end

    if actions.include? :update
      it 'forbids update' do
        put :update, params
        response.code.should == '403'
      end
    end

    if actions.include? :destroy
      it 'forbids delete' do
        post :destroy, params
        response.code.should == '403'
      end
    end
  end

  context 'as the admin user' do
    let(:user) { users(:admin) }
    before { log_in user }

    if actions.include? :create
      it 'forbids create' do
        post :create, params
        response.code.should_not == '403'
      end
    end

    if actions.include? :update
      it 'forbids update' do
        put :update, params
        response.code.should_not == '403'
      end
    end

    if actions.include? :destroy
      it 'forbids delete' do
        post :destroy, params
        response.code.should_not == '403'
      end
    end
  end
end
