describe("chorus.Mixins.SQLResults", function() {
    var HostModel;

    beforeEach(function() {
        HostModel = chorus.models.Base.include(chorus.Mixins.SQLResults);
    });

    describe("#getRows", function() {
        beforeEach(function() {
            this.host = new HostModel();
        });
        context("when rows exist", function() {
            beforeEach(function() {
                this.host.set({
                    rows: [[1, 2, 3]],
                    columns: [
                        { name: 'id'},
                        { name: 'title'},
                        { name: 'whatever'}
                    ]
                });
            });

            it("puts rows into the format data grids expect", function() {
                expect(this.host.getRows()).toEqual([
                    {id_0: 1, title_1: 2, whatever_2: 3}
                ]);
            });
        });
        context("when rows is not defined", function() {
            it("returns an empty array", function() {
                expect(this.host.getRows()).toEqual([]);
            });
        });
    });

    describe("#getColumns", function() {
        beforeEach(function() {
            this.host = new HostModel();
            this.host.set("columns", [{name: "dog"}, {name: "cat"}, {name: "dog"}, {name: "dog_0"}]);
        });

        it("creates unique names for the columns", function() {
            expect(_.pluck(this.host.getColumns(), "name")).toEqual(["dog", "cat", "dog", "dog_0"]);
            var uniqueNames = _.pluck(this.host.getColumns(), "uniqueName");
            expect(_.uniq(uniqueNames)).toEqual(uniqueNames);
        });

        it("returns predictable unique names", function() {
            var firstSet = _.map(this.host.getColumns(), function(column) {
                return _.clone(column);
            });
            var secondSet = this.host.getColumns();
            expect(firstSet).toEqual(secondSet);
        });
    });

    describe("#hasResults", function() {
        beforeEach(function() {
            this.host = new HostModel();
        });

        it("returns true when rows exist", function() {
            expect(this.host.hasResults()).toBe(false);
            this.host.set({
                rows: [[1, 2, 3]],
                columns: [
                    { name: 'id'},
                    { name: 'title'},
                    { name: 'whatever'}
                ]
            });
            expect(this.host.hasResults()).toBe(true);
        });
    });
});

