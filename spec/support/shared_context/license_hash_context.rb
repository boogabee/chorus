shared_context 'license hash' do
  let(:vendor) { 'openchorus' }
  let(:level) { 'openchorus' }
  let(:admins) { 10 }
  let(:developers) { 100 }
  let(:collaborators) { 1000 }
  let(:expires) { 2.months.from_now.to_date }
  let(:license_hash) do
    {
        :vendor => vendor,
        :level => level,
        :admins => admins,
        :developers => developers,
        :collaborators => collaborators,
        :expires => expires
    }
  end
end
