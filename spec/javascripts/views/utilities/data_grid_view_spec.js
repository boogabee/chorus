describe("chorus.views.DataGrid", function() {
    beforeEach(function() {
        this.task = backboneFixtures.dataPreviewTaskResults({
            columns: [
                { name: "id", typeCategory: "WHOLE_NUMBER" },
                { name: "city", typeCategory: "OTHER" },
                { name: "state", typeCategory: "OTHER" },
                { name: "zip", typeCategory: "OTHER" }
            ],
            rows: [
                [1, "Oakland", "CA", "94612"],
                [2, "Arcata", "CA", "95521"] ,
                [3, "Lafayette", "IN", null]
            ]
        });

        this.view = new chorus.views.DataGrid({ model: this.task });

        spyOn(this.view, 'forceFitColumns').andCallThrough();
    });

    describe("falsy data", function() {
        it("outputs a string 0 for a numeric 0", function() {
            this.task.get("rows")[0] = [0];
            this.view.render();

            expect(this.view.$(".slick-row:eq(0) .slick-cell:eq(0)").text()).toBe("0");
        });

        it("outputs a string false for a boolean false", function() {
            this.task.get("rows")[0] = [false];
            this.view.render();

            expect(this.view.$(".slick-row:eq(0) .slick-cell:eq(0)").text()).toBe("false");
        });

        it("outputs empty string for a null", function() {
            this.task.get("rows")[0] = [null];
            this.view.render();

            expect(this.view.$(".slick-row:eq(0) .slick-cell:eq(0)").html()).toBe("");
        });
    });

    describe("#render", function() {
        beforeEach(function() {
            this.view.render();
        });

        describe('resizeGridToResultsConsole', function() {
            it("resizes the data grid", function () {
                spyOn(this.view.grid, 'resizeCanvas');
                spyOn(this.view.grid, 'invalidate');
                this.view.resizeGridToResultsConsole();

                expect(this.view.grid.resizeCanvas).toHaveBeenCalled();
                expect(this.view.grid.invalidate).toHaveBeenCalled();
            });
        });

        it("sets the cell's value as a title tag on each cell", function () {
            var $originCell = this.view.$(".slick-row:eq(0) .slick-cell:eq(0) span");
            expect($originCell.attr('title')).toBe($originCell.text());
        });

        it("renders a column for every column of the result", function() {
            expect(this.view.$(".slick-header-column").length).toBe(4);
        });

        it("renders a column header for each column, with the column's name", function() {
            var columNames = ["id", "city", "state", "zip"];

            _(columNames).each(_.bind(function(columName, i){
                expect(this.view.$(".slick-header-column:eq("+i+")").text()).toBe(columName);
            }, this));
        });

        describe("clicking on a cell", function () {
            beforeEach(function () {
                $("#jasmine_content").append(this.view.$el);
                this.cell = this.view.$(".slick-row:eq(0) .slick-cell:eq(0)");
                this.cell.trigger('click');
            });

            it("selects the cell's value", function () {
                var selection = window.getSelection();
                expect(selection.focusNode.textContent).toBe(this.cell.text());
            });
        });

        describe("force-fitting columns", function () {
            beforeEach(function () {
                this.columns = this.task.get("columns");
            });

            it("determined when initializing the data grid", function () {
                expect(this.view.forceFitColumns).toHaveBeenCalled();
            });

            context("when columns do not fill the viewport", function () {
                beforeEach(function () {
                    this.view.$el.width(25);
                    this.view.columnStartingWidth = 5;
                });
                it("is true", function () {
                    expect(this.view.forceFitColumns(this.columns)).toBe(true);
                });
            });

            context("when columns fill the viewport", function () {
                beforeEach(function () {
                    this.view.$el.width(15);
                    this.view.columnStartingWidth = 5;
                });

                it("is false", function () {
                    expect(this.view.forceFitColumns(this.columns)).toBe(false);
                });
            });
        });
    });
});
