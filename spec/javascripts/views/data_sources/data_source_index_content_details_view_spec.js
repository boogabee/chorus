describe("chorus.views.DataSourceIndexContentDetails", function() {
    beforeEach(function() {
        var dataSources = new chorus.collections.DataSourceSet([
            backboneFixtures.gpdbDataSource(),
            backboneFixtures.gpdbDataSource()
        ]);
        var hdfsDataSources = new chorus.collections.HdfsDataSourceSet([
            backboneFixtures.hdfsDataSource(),
            backboneFixtures.hdfsDataSource()
        ]);
        var gnipDataSources = new chorus.collections.GnipDataSourceSet([
            backboneFixtures.gnipDataSource(),
            backboneFixtures.gnipDataSource()
        ]);

        this.view = new chorus.views.DataSourceIndexContentDetails({
            dataSources: dataSources,
            hdfsDataSources: hdfsDataSources,
            gnipDataSources: gnipDataSources
        });
        spyOn(chorus.PageEvents, "trigger").andCallThrough();
    });

    describe('#render', function() {
        beforeEach(function(){
            this.view.render();
        });

        it("displays the loading text", function() {
            expect(this.view.$(".loading_section")).toExist();
        });
    });

    describe("when the data sources are loaded", function() {
        beforeEach(function() {
            this.view.dataSources.loaded = true;
            this.view.dataSources.trigger('loaded');
            this.view.hdfsDataSources.loaded = true;
            this.view.hdfsDataSources.trigger('loaded');
            this.view.gnipDataSources.loaded = true;
            this.view.gnipDataSources.trigger('loaded');
        });

        it("doesn't display the loading text", function() {
            expect(this.view.$(".loading_section")).not.toExist();
        });

        it('shows the data sources count', function() {
            expect(this.view.$(".number")).toContainText(6);
        });

        describe("multiple selection", function() {
            describe("when the 'select all' link is clicked", function() {
                it("triggers the 'selectAll' page event", function() {
                    this.view.$(".select_all").prop("checked", true);
                    this.view.$(".select_all").change();
                    expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("selectAll");
                });
            });

            describe("when the 'select none' link is clicked", function() {
                it("triggers the 'selectNone' page event", function() {
                    this.view.$(".select_all").prop("checked", false);
                    this.view.$(".select_all").change();
                    expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("selectNone");
                });
            });

            it("renders the checked state", function () {
                this.view.$(".select_all").prop("checked", true).change();
                this.view.render();
                expect(this.view.$(".select_all").prop("checked")).toBeTruthy();
            });
        });
    });
});