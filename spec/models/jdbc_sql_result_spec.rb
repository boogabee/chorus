require 'spec_helper'

describe JdbcSqlResult do
  subject { JdbcSqlResult.new }

  it 'has JdbcDatasetColumn column type class' do
    subject.add_column('id', 'integer')
    subject.columns.first.should be_a JdbcDatasetColumn
  end

end
