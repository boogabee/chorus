describe("chorus.views.NewTableImportDataGrid", function() {
    beforeEach(function() {
        this.columns = [
            {name: "col1", type: "text", values: ["val1.1", "val2.1", "val3.1"]},
            {name: "col2", type: "text", values: ["val1.2", "val2.2", "val3.2"]},
            {name: "col3", type: "text", values: ["val1.3", "val2.3", "val3.3"]},
            {name: "col4", type: "text", values: ["val1.4", "val2.4", "val3.4"]},
            {name: "col5", type: "text", values: ["val1.5", "val2.5", "val3.5"]}
        ];

        this.rows = [
            ["val1.1", "val1.2", "val1.3", "val1.4", "val1.5"],
            ["val2.1", "val2.2", "val2.3", "val2.4", "val2.5"],
            ["val3.1", "val3.2", "val3.3", "val3.4", "val3.5"]
        ];

        this.columnNames = ["col1", "col2", "col3", "col_4", "col_5"];

        this.view = new chorus.views.NewTableImportDataGrid();
        $('#jasmine_content').append(this.view.el);
        this.view.render();
        this.view.initializeDataGrid(this.columns, this.rows, this.columnNames);
    });

    it("converts the column names into db friendly format", function() {
        var $inputs = this.view.$(".column_name input");
        expect($inputs.eq(0).val()).toBe("col1");
        expect($inputs.eq(1).val()).toBe("col2");
        expect($inputs.eq(2).val()).toBe("col3");
        expect($inputs.eq(3).val()).toBe("col_4");
        expect($inputs.eq(4).val()).toBe("col_5");
    });

    it("has the right number of column data types", function() {
        expect(this.view.$(".type").length).toEqual(5);
    });

    it("has the right number of data columns", function() {
        expect(this.view.$(".column_name").length).toEqual(5);
    });

    it("displays the provided types with their associated classes", function() {
        _.each(this.view.$(".type"), function(type, index) {
            expect($(type).find(".chosen").text().trim()).toBe(this.columns[index].type);
            expect($(type)).toHaveClass(this.columns[index].type);
        }, this);
    });

    it("has the right data in each cell", function() {
        $("#jasmine_content").append("<div class='foo'></div>");
        //If you assign the dialog element directly to #jasmine_content, the later teardown will destroy jasmine content
        this.view.setElement($("#jasmine_content .foo"));
        var grid = this.view.grid;
        _.each(this.view.$(".import_data_grid .column_name"), function(column, i) {
            var cells = _.map([0,1,2], function(j){
                return grid.getCellNode(j, i);
            });

            expect(cells.length).toEqual(3);
            _.each(cells, function(cell, j) {
                expect($(cell)).toContainText("val" + (j + 1) + "." + (i + 1));
            });
        });
    });

    describe("selecting a new data type", function() {
        beforeEach(function() {
            this.$type = this.view.$(".type").eq(1);
            this.$type.find(".chosen").click();

            this.$type.find(".popup_filter li").eq(1).find("a").click();
        });

        it("changes the type of the column", function() {
            expect(this.$type.find(".chosen")).toHaveText("double precision");
            expect(this.$type).toHaveClass("double_precision");
        });
    });

    describe("#getColumnNames", function() {
        it("returns an array of the column names extracted from the DOM", function() {
            expect(this.view.getColumnNames()).toEqual(["col1", "col2", "col3", "col_4", "col_5"]);
        });
    });

    describe("#getColumnTypes", function(){
        it("returns an array of the column types extracted from the DOM", function(){
            expect(this.view.getColumnTypes()).toEqual(["text","text","text","text","text"]);
        });
    });

    describe("#markColumnNameInputAsInvalid", function() {
        it("marks the column name input with the given index as invalid", function() {
            this.view.markColumnNameInputAsInvalid(2);
            expect(this.view.$(".column_name input").eq(2)).toHaveClass("has_error");
        });
    });
});