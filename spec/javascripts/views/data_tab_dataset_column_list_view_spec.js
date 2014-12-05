describe("chorus.views.DataTabDatasetColumnList", function() {
    beforeEach(function() {
        spyOn($.fn, "draggable");

        this.dataset = backboneFixtures.dataset({ objectName: "brian_the_table", schema: {name: "john_the_schema"} });
        this.view = new chorus.views.DataTabDatasetColumnList({ dataset: this.dataset });
    });

    it("should fetch the columns for the table", function() {
        expect(this.server.lastFetchFor(this.dataset.columns(), {page: 1, per_page: 1000})).toBeDefined();
    });

    describe("before the columns load", function() {
        beforeEach(function() {
            this.view.render();
        });

        it("should show a loading spinner", function() {
            expect(this.view.$(".loading_section")).toExist();
        });
    });

    context("after the columns load", function() {
        context("when there are no columns", function() {
            beforeEach(function() {
                this.server.completeFetchAllFor(this.dataset.columns(), []);
            });

            it("should show the 'no columns found' message", function() {
                expect(this.view.$(".none_found")).toContainTranslation("schema.column.list.empty");
            });
        });

        context("when there are columns", function() {
            beforeEach(function() {
                this.columnA = backboneFixtures.databaseColumn({name: "column_1", dataType: "text" });
                this.columnB = backboneFixtures.databaseColumn({name: "column_2", dataType: "timestamp with time zone"});

                this.server.completeFetchAllFor(this.dataset.columns(), [
                    this.columnA,
                    this.columnB
                ]);
            });

            it("should show an 'li' for each column", function() {
                expect(this.view.$("li").length).toBe(2);
                expect(this.view.$("li").eq(0)).toContainText("[" + this.columnA.get('dataType') + "] " + this.columnA.get('name'));
                expect(this.view.$("li").eq(1)).toContainText("[" + this.columnB.get('dataType') + "] " + this.columnB.get('name'));
            });

            describe("draggable setup", function() {
                it("should have data-cid on the list elements", function() {
                    expect(this.view.$('li').data('cid')).toBeTruthy();
                });

                it("should have the fullname on the list elements", function() {
                    expect(this.view.$('li:eq(0)').data('fullname')).toEqual('"column_1"');
                    expect(this.view.$('li:eq(1)').data('fullname')).toEqual('"column_2"');
                });

                it("should make the list elements draggable", function() {
                    expect($.fn.draggable).toHaveBeenCalledOnSelector("li");
                });

                it("uses a draggable helper that has the name of the table", function() {
                    var $li = this.view.$("li:eq(0)");
                    var helper = this.view.dragHelper({currentTarget: $li});
                    expect(helper).toHaveClass("drag_helper");
                    expect(helper).toContainText($li.data("name"));
                });
            });
        });
    });
});
