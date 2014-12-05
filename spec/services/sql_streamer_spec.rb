require 'spec_helper'

describe SqlStreamer do
  let(:sql) { "select 1;" }
  let(:row_limit) { nil }
  let(:options) { { :quiet_null => false } }
  let(:streamer) { SqlStreamer.new(sql, connection, options) }
  let(:streamer_options) { { :quiet_null => false, :rescue_connection_errors => false } }

  let(:streamed_data) { [
      {:id => 1, :something => 'hello'},
      {:id => 2, :something => 'cruel' },
      {:id => 3, :something => 'world'}
  ] }

  let(:connection) do
    obj = Object.new
    mock(obj).stream_sql(sql, hash_including(streamer_options), anything) do |sql, options, cancelable_query, block|
      streamed_data.each { |row| block.call row }
      true
    end

    obj
  end

  describe "#enum" do
    it "returns an enumerator that yields the header and rows from the sql in csv" do
      check_enumerator(streamer.enum)
    end

    context "when the headers are hidden" do
      let(:options) {{:show_headers => false}}

      it "should not yield the header row" do
        check_enumerator(streamer.enum, false)
      end
    end

    context "with special characters in the data" do
      let(:streamed_data) {
        [{
             :id => 1,
             :double_quotes => %Q{with"double"quotes},
             :single_quotes => %Q{with'single'quotes},
             :comma => 'with,comma'
         }]
      }

      it "escapes the characters in the csv" do
        enumerator = streamer.enum.to_a
        first_record = enumerator[1]

        first_record.should == %Q{1,"with""double""quotes",with'single'quotes,"with,comma"\n}
      end

      describe "when the sql streamer has greenplum as target" do
        let(:streamer) { SqlStreamer.new(sql, connection, { target_is_greenplum: true }) }

        let(:streamed_data) do
          [{
             :id => 1,
             :newline => '\n',
             :carriage_return => '\r',
             :null => '\0'
           }]
        end

        it "converts special characters to whitespace or empty string" do
          enumerator = streamer.enum.to_a
          first_record = enumerator[1]
          first_record.should == "1, , ,\"\"\n"
        end
      end
    end

    context "with row_limit" do
      let(:options) { { :row_limit => 2 } }
      let(:streamer_options) { { :limit => 2, :quiet_null => false } }

      it "uses the limit" do
        enumerator = streamer.enum
        enumerator.next
        finish_enumerator(enumerator)
      end
    end

    context "with quiet null" do
      let(:options) { { :quiet_null => true } }
      let(:streamer_options) { { :quiet_null => true } }

      it "uses the limit" do
        enumerator = streamer.enum
        enumerator.next
        finish_enumerator(enumerator)
      end
    end

    context "connection errors" do
      let(:streamer_options) { options }

      let(:connection) {
        obj = Object.new
        mock(obj).stream_sql(sql, streamer_options, anything) do |sql, options, block|
          raise PostgresLikeConnection::DatabaseError, StandardError.new("Some friendly error message")
        end

        obj
      }

      context "when you want to raise errors" do
        let(:options) { {:quiet_null => true, :rescue_connection_errors => false } }
        it "raises error" do
          expect {
            streamer.enum.next
          }.to raise_error(PostgresLikeConnection::DatabaseError)
        end
      end

      context "when errors should be rescued" do
        let(:options) { {:quiet_null => true, :rescue_connection_errors => true } }

        it "returns the error message" do
          enumerator = streamer.enum
          enumerator.next.should == "Some friendly error message"
          finish_enumerator enumerator
        end
      end
    end

    context "for results with no rows" do
      let(:streamed_data) { [] }

      it "returns the error message" do
        enumerator = streamer.enum
        enumerator.next.should == "The query returned no rows"
        finish_enumerator(enumerator)
      end
    end

    context "with a cancelable query" do
      let(:cancelable_query) { Object.new }
      let(:streamer) { SqlStreamer.new(sql, connection, options, cancelable_query) }

      it 'cleans up statements on enum.close' do
        mock(cancelable_query).clean_statement
        enum = streamer.enum
        finish_enumerator(enum)
        enum.close
      end
    end

    def check_enumerator(enumerator, show_headers=true)
      results = enumerator.to_a

      if show_headers
        results.length.should eq(4)
        results[0].should == "id,something\n"
        results[1].should == "1,hello\n"
        results[2].should == "2,cruel\n"
        results[3].should == "3,world\n"
      else
        results.length.should eq(3)
        results[0].should == "1,hello\n"
        results[1].should == "2,cruel\n"
        results[2].should == "3,world\n"
      end
    end

    def finish_enumerator(enum)
      while true
        enum.next
      end
    rescue
    end
  end
end
