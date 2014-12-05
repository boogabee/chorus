describe("chorus.pages.DatasetShowPage", function () {
    beforeEach(function () {
        this.dataset = backboneFixtures.dataset();
        this.columnSet = this.dataset.columns();
        this.page = new chorus.pages.DatasetShowPage(
            this.dataset.id
        );
    });

    it("includes the DataSourceCredentials mixin", function () {
        expect(this.page.dependentResourceForbidden).toBe(chorus.Mixins.DataSourceCredentials.page.dependentResourceForbidden);
    });

    it("has a helpId", function () {
        expect(this.page.helpId).toBe("dataset");
    });

    it("has the right #failurePageOptions (for populating the content of a 404 page)", function () {
        var options = this.page.failurePageOptions();
        expect(options.title).toMatchTranslation("invalid_route.dataset.title");
        expect(options.text).toMatchTranslation("invalid_route.dataset.content");
    });

    it("fetches a database object", function () {
        expect(this.page.dataset).toHaveBeenFetched();
    });

    describe("#initialize", function () {
        context("when the dataset fetch completes", function () {
            beforeEach(function () {
                this.server.completeFetchFor(this.dataset);
            });

            describe("when the columnSet fetch completes", function () {
                context("with valid data", function () {

                    beforeEach(function () {
                        this.server.completeFetchAllFor(this.columnSet);
                    });

                    it("sets the main content as persistent", function () {
                        expect(this.page.mainContent.persistent).toBeTruthy();
                    });

                    it("creates the sidebar", function () {
                        expect(this.page.sidebar).toBeDefined();
                        expect(this.page.sidebar.resource).toBe(this.page.dataset);
                    });

                    it("does not set workspace", function () {
                        expect(this.page.sidebar.options.workspace).toBeFalsy();
                    });
                });
                context("with errors", function () {
                    beforeEach(function () {
                        this.server.lastFetchAllFor(this.columnSet).failForbidden({message: "No permission"});
                    });

                    it("puts the errors on the new column set", function () {
                        //so deriving a chorus view and adding columns through table joins doesn't have side effects
                        expect(this.page.columnSet.serverErrors).toEqual({message: "No permission"});
                    });
                });
            });
        });
    });

    describe("#render", function () {
        beforeEach(function () {
            this.dataset.loaded = false;
            this.page.render();
        });

        it("shows a loading spinner until the fetches complete", function () {
            expect($(this.page.mainContent.el)).toHaveClass('loading_section');
        });
    });

    context("when the dataset fetch completes", function () {
        beforeEach(function () {
            spyOn(chorus, "search");
            this.page.render();
            this.qtipSpy = stubQtip();
            this.resizedSpy = spyOnEvent(this.page, 'resized');
            this.server.completeFetchFor(this.dataset);
        });

        describe("breadcrumbs", function () {
            it("has the right breadcrumbs", function () {
                var breadcrumbs = this.page.$("#breadcrumbs .breadcrumb a");

                expect(breadcrumbs.length).toBe(5);

                expect(breadcrumbs.eq(0).attr("href")).toBe("#/");
                expect(breadcrumbs.eq(0).text()).toBe(t("breadcrumbs.home"));

                expect(breadcrumbs.eq(1).attr("href")).toBe("#/data_sources");
                expect(breadcrumbs.eq(1).text()).toBe(t("breadcrumbs.data_sources"));

                expect(breadcrumbs.eq(2)).toHaveHref(this.dataset.dataSource().databases().showUrl());
                expect(breadcrumbs.eq(2)).toContainText(this.dataset.dataSource().name());

                expect(breadcrumbs.eq(3)).toHaveHref(this.dataset.database().showUrl());
                expect(breadcrumbs.eq(3)).toContainText(this.dataset.database().name());

                expect(breadcrumbs.eq(4).attr("href")).toBe(this.dataset.schema().showUrl());
                expect(breadcrumbs.eq(4)).toContainText(this.dataset.schema().name());

                expect(this.page.$("#breadcrumbs .breadcrumb .slug")).toContainText(this.dataset.name());
            });

            describe("when the dataset does not have a database", function() {
                beforeEach(function() {
                    this.dataset = backboneFixtures.oracleDataset();
                    this.page = new chorus.pages.DatasetShowPage(this.dataset.id);
                    this.page.render();
                    this.server.completeFetchFor(this.dataset);
                });

                it("shows everything but the database breadcrumbs", function() {
                    var breadcrumbs = this.page.$("#breadcrumbs .breadcrumb a");
                    expect(breadcrumbs.length).toBe(4);

                    expect(breadcrumbs.eq(0).attr("href")).toBe("#/");
                    expect(breadcrumbs.eq(0).text()).toBe(t("breadcrumbs.home"));

                    expect(breadcrumbs.eq(1).attr("href")).toBe("#/data_sources");
                    expect(breadcrumbs.eq(1).text()).toBe(t("breadcrumbs.data_sources"));

                    expect(breadcrumbs.eq(2)).toHaveHref(this.dataset.dataSource().showUrl());
                    expect(breadcrumbs.eq(2)).toContainText(this.dataset.dataSource().name());

                    expect(breadcrumbs.eq(3).attr("href")).toBe(this.dataset.schema().showUrl());
                    expect(breadcrumbs.eq(3)).toContainText(this.dataset.schema().name());

                    expect(this.page.$("#breadcrumbs .breadcrumb .slug")).toContainText(this.dataset.name());
                });
            });
        });

        describe("#contentDetails", function () {
            it("does not have a Derive Chorus View button", function () {
                expect(this.page.$(".derive")).not.toExist();
            });

            it("does not have a publish to Tableau button", function () {
                chorus.models.Config.instance().set({ tableauConfigured: true });
                this.page.render();
                expect(this.page.$("button.publish")).not.toExist();
            });
        });

        context("when the columns and statistics fetches complete", function () {
            beforeEach(function () {
                this.server.completeFetchAllFor(this.columnSet, [backboneFixtures.databaseColumn(), backboneFixtures.databaseColumn()]);
                this.server.completeFetchFor(this.dataset.statistics());
            });

            it("renders the header", function () {
                expect(this.page.$('h1')).toContainText(this.dataset.name());
            });

            it("hides the loading spinner", function () {
                expect($(this.page.mainContent.el)).not.toHaveClass('loading_section');
            });

            it("has a search field in the content details that filters the column list", function () {
                var searchInput = this.page.mainContent.contentDetails.$("input.search"),
                    columnList = $(this.page.mainContent.content.el);

                expect(searchInput).toExist();
                expect(chorus.search).toHaveBeenCalled();
                var searchOptions = chorus.search.lastCall().args[0];

                expect(searchOptions.input).toBe(searchInput);
                expect(searchOptions.list).toBe(columnList);
            });
        });
    });

    context('when the dataset fetch fails with errors', function () {
        beforeEach(function () {
            spyOn(Backbone.history, "loadUrl");

            this.server.lastFetchFor(this.dataset).failUnprocessableEntity(
                { record: 'MISSING_DB_OBJECT' });
        });

        it('stays on the page', function () {
            expect(Backbone.history.loadUrl).not.toHaveBeenCalled();
        });

        it("renders the header", function () {
            expect(this.page.$('h1')).toExist();
        });

        it('shows the error bar', function () {
            expect(this.page.$('div.dataset_errors')).toExist();
        });

        it('does not fetch the columns', function () {
            expect(this.server.lastFetchFor(this.dataset.columns())).toBeUndefined();
        });
    });

    context("when the dataset fetch 404s", function () {
        beforeEach(function () {
            spyOn(Backbone.history, "loadUrl");
            this.server.lastFetchFor(this.dataset).failNotFound();
        });

        it("navigates to the 404 page", function () {
            expect(Backbone.history.loadUrl).toHaveBeenCalledWith("/invalidRoute");
        });
    });

    context("when the dataset fetch 403s", function () {
        beforeEach(function () {
            this.errorJson = backboneFixtures.invalidCredentialsErrorJson(
                {errors: { model_data: {owner_id: 'some_nonsense', shared: true } } }
            );
            spyOn(Backbone.history, "loadUrl");
            this.server.lastFetchFor(this.dataset).failForbidden(this.errorJson.errors);
        });

        it("navigates to the 403 page", function () {
            expect(Backbone.history.loadUrl).toHaveBeenCalledWith("/forbidden");
        });

        it("displays an appropriate explanation", function() {
            expect(chorus.pageOptions.title).toMatchTranslation("data_sources.shared_account_invalid.title");
            expect(chorus.pageOptions.text).toMatchTranslation("data_sources.shared_account_invalid.text");
        });
    });
});
