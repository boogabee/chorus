chorus.utilities.CsvParser = function(contents, options) {
    this.contents = contents;
    this.options = _.extend({
        hasHeader: true,
        delimiter: ","
    }, options);
    var rows = [];

    this.setOptions = function(options) {
        _.extend(this.options, options);
    };

    this.parse = function() {
        var parser = new CSV();

        try {
            parser.from(this.contents, {delimiter: this.options.delimiter});
            delete this.serverErrors;
        } catch (e) {
            if (e instanceof CSV.ParseError) {
                this.serverErrors = {fields: {delimiter: {INVALID: {}}}};
                return [];
            } else {
                throw (e);
            }
        }

        rows = parser.lines;
    };

    this.parse();

    this.generateColumnNames = function() {
        return _.map(rows[0], function(column, i) {
            return "column_" + (i + 1);
        });
    };

    this.parseColumnNames = function() {
        return _.map(rows[0], chorus.utilities.CsvParser.normalizeColumnName);
    };

    this.rows = function() {
        return this.options.hasHeader ? rows.slice(1) : rows;
    };

    this.getColumnOrientedData = function() {
        var columnNames;
        if(this.options.hasHeader) {
            columnNames = this.parseColumnNames();
        } else {
            columnNames = this.generateColumnNames();
        }
        if (this.options.columnNameOverrides) {
            columnNames = this.options.columnNameOverrides;
        }

        var rows = this.rows();
        var columnCount = rows[0] ? rows[0].length : 0;
        var types = this.options.types;
        if (!types || types.length !== columnCount) {
            types = _.map(columnNames, function(columnName, i) {
                var containsSomeText = false;
                var allEmpty = true;
                _.each(rows, function(row) {
                    var contents = row[i];
                    var isText = contents && isNaN(+contents);
                    var isEmpty = !contents || contents.trim() === '';
                    allEmpty = allEmpty && isEmpty;
                    containsSomeText = containsSomeText || isText;
                }, this);
                return allEmpty || containsSomeText ? 'text' : 'double_precision';
            }, this);
        }

        return _.map(columnNames, function(columnName, i) {
            var columnValues = [];
            _.each(rows, function(row) {
                columnValues.push(row[i] || "");
            });
            return {values: columnValues, name: columnName, type: types[i]};
        }, this);
    };

    return this;
};

chorus.utilities.CsvParser.normalizeForDatabase = function(str) {
    return str.trim().toLowerCase().replace(/[\s.]/g, "_").replace(/[^a-z0-9_]/g, '').substring(0, 64);
};

chorus.utilities.CsvParser.normalizeColumnName = function(str) {
    return chorus.utilities.CsvParser.normalizeForDatabase(str.toLowerCase());
};

