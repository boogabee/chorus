shared_examples 'dataset access control' do
  before do
    stub(context).current_user { user }
  end

  describe '#show?' do
    context 'if the user is an admin' do
      let(:user) { users(:admin) }

      it 'allows access' do
        access.can?(:show, dataset).should be_true
      end
    end

    context 'if the user has access to the data source containing the dataset' do
      let(:user) { users(:the_collaborator) }

      it 'allows access' do
        access.can?(:show, dataset).should be_true
      end
    end

    context 'if the user does not have access to the data source containing the dataset' do
      let(:user) { users(:the_collaborator) }

      before do
        any_instance_of(DataSourceAccess) do |instance|
          stub(instance).can? :show, dataset.data_source { false }
        end
      end

      it 'prevents access' do
        access.can?(:show, dataset).should be_false
      end
    end
  end
end
