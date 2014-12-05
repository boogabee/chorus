describe("chorus.views.ImportDataGrid", function () {
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

        this.view = new chorus.views.ImportDataGrid(this.$element);
        spyOn(this.view, 'forceFitColumns').andCallThrough();
        spyOn(Slick, "Grid").andCallThrough();
        spyOn(this.view, 'inDocument');
    });

    describe("rendering", function() {
        beforeEach(function () {
            this.view.inDocument.andReturn(true);
            this.view.render();
            this.view.initializeDataGrid(this.columns, this.rows, this.columnNames);
        });

        it("initializes SlickGrid", function() {
            expect(Slick.Grid).toHaveBeenCalled();
        });

        describe("force-fitting columns", function () {
            it("determined when initializing the data grid", function () {
                expect(this.view.forceFitColumns).toHaveBeenCalled();
            });

            context("when columns do not fill the viewport", function () {
                beforeEach(function () {
                    this.view.$el.width(550);
                });
                it("is true", function () {
                    expect(this.view.forceFitColumns(this.columns)).toBe(true);
                });
            });

            context("when columns fill the viewport", function () {
                beforeEach(function () {
                    this.view.$el.width(450);
                });

                it("is false", function () {
                    expect(this.view.forceFitColumns(this.columns)).toBe(false);
                });
            });
        });

        describe("resizing the grid", function () {
            context("when the grid is not in the DOM", function () {
                beforeEach(function () {
                    this.view.inDocument.andReturn(false);
                });
                it("does not happen", function () {
                    spyOn(this.view.grid, 'resizeCanvas');
                    spyOn(this.view.grid, 'invalidate');

                    this.view.resizeGridToResultsConsole();

                    expect(this.view.grid.resizeCanvas).not.toHaveBeenCalled();
                    expect(this.view.grid.invalidate).not.toHaveBeenCalled();
                });
            });
        });
    });

    context("when the view is not in the DOM", function () {
        beforeEach(function () {
            this.view.inDocument.andReturn(false);
        });

        it("does not initialize", function () {
            this.view.initializeDataGrid();
            expect(this.grid).toBe(undefined);
        });
    });
});