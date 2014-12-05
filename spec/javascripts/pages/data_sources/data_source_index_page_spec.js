describe("chorus.pages.DataSourceIndexPage", function() {
    beforeEach(function() {
        this.page = new chorus.pages.DataSourceIndexPage();
        this.dataSourceSet = new chorus.collections.DataSourceSet([], {all: true});
        this.hdfsDataSourceSet = new chorus.collections.HdfsDataSourceSet();
        this.gnipDataSourceSet = new chorus.collections.GnipDataSourceSet();
    });

    describe("calls the handleFetchErrorsFor function", function() {
        beforeEach(function() {
            this.originalhandleFetchErrorsFor = chorus.pages.DataSourceIndexPage.handleFetchErrorsFor;
            spyOn(chorus.pages.DataSourceIndexPage.prototype, 'handleFetchErrorsFor');
        });

        it("handleFetchErrorsFor the data sources", function() {
            var page = new chorus.pages.DataSourceIndexPage();
            expect(page.handleFetchErrorsFor.calls.count()).toEqual(3);
            expect(page.handleFetchErrorsFor.nthCall(0).args[0].constructor).toBe(chorus.collections.DataSourceSet);
            expect(page.handleFetchErrorsFor.nthCall(1).args[0].constructor).toBe(chorus.collections.HdfsDataSourceSet);
            expect(page.handleFetchErrorsFor.nthCall(2).args[0].constructor).toBe(chorus.collections.GnipDataSourceSet);
        });

        afterEach(function() {
            chorus.pages.DataSourceIndexPage.handleFetchErrorsFor = this.originalhandleFetchErrorsFor;
        });
    });

    it("has a helpId", function() {
        expect(this.page.helpId).toBe("instances");
    });

    it("fetches all data sources", function() {
        expect(this.dataSourceSet).toHaveBeenFetched();
    });

    it('fetches all hadoop data sources', function() {
        expect(this.hdfsDataSourceSet).toHaveBeenFetched();
    });

    it('fetches all gnip data sources', function() {
        expect(this.gnipDataSourceSet).toHaveBeenFetched();
    });

    it('passes the data sources and hadoop data sources to the content details view', function() {
        var contentDetails = this.page.mainContent.contentDetails;
        expect(contentDetails.options.hdfsDataSources).toBeA(chorus.collections.HdfsDataSourceSet);
        expect(contentDetails.options.dataSources).toBeA(chorus.collections.DataSourceSet);
        expect(contentDetails.options.gnipDataSources).toBeA(chorus.collections.GnipDataSourceSet);
    });

    it('passes the data sources, hadoop and gnip data sources to the list view', function() {
        var list = this.page.mainContent.content;
        expect(list.options.hdfsDataSources).toBeA(chorus.collections.HdfsDataSourceSet);
        expect(list.options.dataSources).toBeA(chorus.collections.DataSourceSet);
        expect(list.options.gnipDataSources).toBeA(chorus.collections.GnipDataSourceSet);
    });

    describe('#render', function(){
        beforeEach(function(){
            chorus.bindModalLaunchingClicks(this.page);
            this.page.render();
        });

        context("when data source creation is not restricted", function() {
            beforeEach(function() {
                spyOn(chorus.models.Config.instance(), 'restrictDataSourceCreation').and.returnValue(false);
                this.page.render();
            });

            itBehavesLike.aPageWithPrimaryActions([
                {name: 'add_data_source', target: chorus.dialogs.DataSourcesNew}
            ]);
        });

        context("when data source creation is restricted", function() {
            beforeEach(function() {
                spyOn(chorus.models.Config.instance(), 'restrictDataSourceCreation').and.returnValue(true);
            });

            context("when the user is an admin", function() {
                beforeEach(function() {
                    setLoggedInUser({ admin: true });
                    this.page.render();
                });

                itBehavesLike.aPageWithPrimaryActions([
                    {name: 'add_data_source', target: chorus.dialogs.DataSourcesNew}
                ]);
            });

            context("when the user is not an admin", function() {
                beforeEach(function() {
                    setLoggedInUser({ admin: false });
                    this.page.render();
                });

                it("does not show the create link", function() {
                    expect(this.page.$(".add_data_source")).not.toExist();
                });
            });
        });

        it("sets the page model when a 'data_source:selected' event is triggered", function() {
            var dataSource = backboneFixtures.gpdbDataSource();
            expect(this.page.model).not.toBe(dataSource);
            chorus.PageEvents.trigger('data_source:selected', dataSource);
            expect(this.page.model).toBe(dataSource);
        });

        it("clears the page model when a 'clear_selection' event is triggered", function() {
            var dataSource = backboneFixtures.gpdbDataSource();
            chorus.PageEvents.trigger('data_source:selected', dataSource);
            chorus.PageEvents.trigger('clear_selection');
            expect(this.page.model).toBeUndefined();
        });

        it("clears the sidebar when a 'clear_selection' event is triggered", function() {
            spyOn(this.page.sidebar, 'clear');
            chorus.PageEvents.trigger('clear_selection');
            expect(this.page.sidebar.clear).toHaveBeenCalled();
        });

        it("displays the loading text", function() {
            expect(this.page.mainContent.contentDetails.$(".loading_section")).toExist();
        });
    });

    describe("when the data sources are fetched", function() {
        beforeEach(function() {
            this.server.completeFetchAllFor(this.dataSourceSet, [
                backboneFixtures.oracleDataSource(),
                backboneFixtures.gpdbDataSource()
            ]);

            this.server.completeFetchAllFor(this.hdfsDataSourceSet, [
                backboneFixtures.hdfsDataSource(),
                backboneFixtures.hdfsDataSource()
            ]);
            this.server.completeFetchAllFor(this.gnipDataSourceSet, [
                backboneFixtures.gnipDataSource(),
                backboneFixtures.gnipDataSource()
            ]);
        });

        it("doesn't display the loading text", function() {
            expect(this.page.mainContent.contentDetails.$(".loading_section")).not.toExist();
        });

        it('displays the data source count', function(){
            expect(this.page.mainContent.contentDetails.$(".number").text()).toBe("6");
        });

        it("fetches all datasets", function() {
            expect(this.server.lastFetchFor(this.dataSourceSet).params().all).toBe("true");
        });

        describe("multiple selection", function() {
            beforeEach(function() {
                this.page.render();
            });

            context("when two rows have been checked", function() {
                beforeEach(function() {
                    this.modalSpy = stubModals();
                    var dataSources = new chorus.collections.DataSourceSet([backboneFixtures.gpdbDataSource(), backboneFixtures.gpdbDataSource()]);
                    chorus.PageEvents.trigger("data_source:checked", dataSources);
                });

                it("displays the multiple selection section", function() {
                    expect(this.page.$(".multiple_selection .actions")).not.toHaveClass("hidden");
                });

                it("has an action to edit tags", function() {
                    expect(this.page.$(".multiple_selection a.edit_tags")).toExist();
                });

                itBehavesLike.aDialogLauncher(".multiple_selection a.edit_tags", chorus.dialogs.EditTags);
            });

            context("when all data sources for a single type are selected", function () {
                beforeEach(function () {
                    _.each(this.page.$(".data_source input[type=checkbox]"), function (element) {
                        $(element).prop("checked", true).click();
                    });
                });

                it("checks the 'select_all' checkbox and marks it as indeterminate", function () {
                    expect(this.page.$(".select_all").prop("checked")).toBeTruthy();
                    expect(this.page.$(".select_all").prop("indeterminate")).toBeTruthy();
                });
            });

            context("when all data sources are selected", function () {
                beforeEach(function () {
                    _.each(this.page.$(".data_source_list input[type=checkbox]"), function (element) {
                        $(element).prop("checked", true).click();
                    });
                });

                it("checks the 'select_all' checkbox", function () {
                    expect(this.page.$(".select_all").prop("checked")).toBeTruthy();
                });
            });
        });
    });
});
