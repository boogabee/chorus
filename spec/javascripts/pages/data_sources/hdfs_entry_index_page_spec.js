describe("chorus.pages.HdfsEntryIndexPage", function() {
    beforeEach(function() {
        this.hdfsDataSource = backboneFixtures.hdfsDataSource({id: 1234, name: "Data Source Name"});
        this.hdfsEntry = backboneFixtures.hdfsDir({
            hdfsDataSource: this.hdfsDataSource.attributes,
            id: 4,
            name: "myDir",
            path: "/foo"
        });
        spyOn(chorus.pages.HdfsEntryIndexPage.prototype, 'setupMultiSelectSidebar').andCallThrough();
        this.page = new chorus.pages.HdfsEntryIndexPage(1234, 4);
    });

    it("has a helpId", function() {
        expect(this.page.helpId).toBe("instances");
    });

    it("fetches the Hdfs entries for that directory", function() {
        expect(this.hdfsEntry).toHaveBeenFetched();
    });

    it('fetches the data source', function() {
        expect(this.hdfsDataSource).toHaveBeenFetched();
    });

    describe('before the data source fetch completes', function() {
        beforeEach(function() {
            this.page.render();
        });

        itBehavesLike.aPageWithPrimaryActions([
            {name: 'add_data', target: chorus.dialogs.HdfsImportDialog}
        ]);

        it("has a loading section on the page", function() {
            expect(this.page.$(".loading_section")).toExist();
        });

        it("has some breadcrumbs", function() {
            expect(this.page.$(".breadcrumb:eq(0) a").attr("href")).toBe("#/");
            expect(this.page.$(".breadcrumb:eq(0)").text().trim()).toMatchTranslation("breadcrumbs.home");

            expect(this.page.$(".breadcrumb:eq(1) a").attr("href")).toBe("#/data_sources");
            expect(this.page.$(".breadcrumb:eq(1)").text().trim()).toMatchTranslation("breadcrumbs.data_sources");
        });
    });

    describe("when all of the fetches complete", function() {
        beforeEach(function() {
            this.server.completeFetchFor(this.hdfsDataSource);
            this.server.completeFetchFor(this.hdfsEntry,
                {
                    ancestors: [],
                    path: "/foo",
                    name: "myDir",
                    entries: [{name: "test.csv"}]
                }
            );
        });

        describe('multiselect', function() {

            it("creates the multi select sidebar", function() {
                expect(this.page.multiSelectSidebarMenu).toBeDefined();
                expect(this.page.multiSelectSidebarMenu).toBeA(chorus.views.MultipleSelectionSidebarMenu);
                expect(this.page.multiSelectSidebarMenu.options.selectEvent).toEqual("hdfs_entry:checked");
            });

            it("sets up the multiselect sidebar when the data source is loaded", function() {
                this.page.setupMultiSelectSidebar.reset();
                this.page.dataSource.trigger('loaded');
                expect(this.page.setupMultiSelectSidebar).toHaveBeenCalled();
            });
        });

        it("has the right breadcrumbs", function() {
            expect(this.page.$(".breadcrumb:eq(0) a").attr("href")).toBe("#/");
            expect(this.page.$(".breadcrumb:eq(0)").text().trim()).toMatchTranslation("breadcrumbs.home");

            expect(this.page.$(".breadcrumb:eq(1) a").attr("href")).toBe("#/data_sources");
            expect(this.page.$(".breadcrumb:eq(1)").text().trim()).toMatchTranslation("breadcrumbs.data_sources");

            expect(this.page.$(".breadcrumb:eq(2)").text().trim()).toBe(this.hdfsDataSource.get("name") + " (2)");

            expect(this.page.$(".breadcrumb").length).toBe(3);
        });

        it("has a sidebar", function() {
            var sidebar = this.page.sidebar;
            expect($(this.page.el).find(sidebar.el)).toExist();
            expect(sidebar).toBeA(chorus.views.HdfsEntrySidebar);
        });

        describe("when an entry is selected", function() {
            beforeEach(function() {
                this.entry = new backboneFixtures.hdfsFile();

                expect(this.page.model).toEqual(this.page.collection.at(0));
                chorus.PageEvents.trigger("hdfs_entry:selected", this.entry);
            });
            it("sets the entry as the model", function() {
                expect(this.page.model).toEqual(this.entry);
            });
        });

        itBehavesLike.aPageWithMultiSelect();
    });

    describe("when the path is long", function () {
        beforeEach(function () {
            spyOn(this.page, "menu");
            this.server.completeFetchFor(this.hdfsDataSource);
            this.server.completeFetchFor(this.hdfsEntry,
                {
                    path: "/start/m1/m2/m3/end",
                    ancestors: [{id: 11, name: "end"},
                        {id: 22, name: "m3"},
                        {id: 33, name: "m2"},
                        {id: 44, name: "m1"},
                        {id: 55, name: "start"}
                    ],
                    name: "foo",
                    entries: []
                }
            );
        });

        it("constructs the breadcrumb links correctly", function () {
            var options = this.page.menu.lastCall().args[1];

            var $content = $(options.content);

            expect($content.find("a").length).toBe(5);

            expect($content.find("a").eq(0).attr("href")).toBe("#/hdfs_data_sources/1234/browse/55");
            expect($content.find("a").eq(1).attr("href")).toBe("#/hdfs_data_sources/1234/browse/44");
            expect($content.find("a").eq(2).attr("href")).toBe("#/hdfs_data_sources/1234/browse/33");
            expect($content.find("a").eq(3).attr("href")).toBe("#/hdfs_data_sources/1234/browse/22");
            expect($content.find("a").eq(4).attr("href")).toBe("#/hdfs_data_sources/1234/browse/11");

            expect($content.find("a").eq(0).text()).toBe("start");
            expect($content.find("a").eq(1).text()).toBe("m1");
            expect($content.find("a").eq(2).text()).toBe("m2");
            expect($content.find("a").eq(3).text()).toBe("m3");
            expect($content.find("a").eq(4).text()).toBe("end");
        });
    });
});
