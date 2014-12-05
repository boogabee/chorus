describe("chorus.utilities.CsvWriter", function() {
    beforeEach(function() {
        this.options = {};
    });

    context("data has both column names and data", function() {
        beforeEach(function() {
            var columnNames = ["col1", "col2", "col3"];
            var uniqueNames = ["col1_0", "col2_1", "col3_2"];
            var rows = [
                {col1_0: "row 11", col2_1: "row 12", col3_2: "row 13"},
                {col1_0: "row 21", col2_1: "row 22", col3_2: "row 23"}
            ];
            this.csvWriter = new chorus.utilities.CsvWriter(columnNames, uniqueNames, rows, this.options);
        });

        it("writes both column name and data", function() {
            expect(this.csvWriter.toCsv()).toBe('"col1","col2","col3"\n"row 11","row 12","row 13"\n"row 21","row 22","row 23"\n');
        });
    });
});
