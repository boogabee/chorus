describe("chorus.pages.WorkspaceSearchIndexPage", function() {
    beforeEach(function() {
        this.workspaceId = '101';
        this.query = 'foo';
        this.page = new chorus.pages.WorkspaceSearchIndexPage(this.workspaceId, "this_workspace", "all", this.query);
        this.workspace = this.page.search.workspace();
    });

    it("fetches the right search result", function() {
        expect(this.page.search.get("query")).toBe("foo");
        expect(this.page.search.get("workspaceId")).toBe("101");
    });

    it("fetches the workspace", function() {
        expect(this.workspace).toHaveBeenFetched();
    });

    context("when the workspace fetch completes", function () {
        beforeEach(function () {
            this.server.completeFetchFor(this.workspace);
        });

        it("has a titlebar", function() {
            expect(this.page.$(".page_sub_header")).toContainText(this.workspace.name());
        });
    });

    describe("when the workspace and search are fetched", function() {
        context("when the search is scoped", function() {
            beforeEach(function() {
                this.server.completeFetchFor(this.page.search, { thisWorkspace: { docs: [], numFound: 0 }});
                this.server.completeFetchFor(this.page.search.workspace(), { id: "101", name: "Bob the workspace" });
            });

            it("disables the 'data sources', 'people', 'hdfs entries' and 'workspaces' options in the filter menu", function() {
                var menuOptions = this.page.$(".default_content_header .link_menu.type li");
                expect(menuOptions.find("a").length).toBe(4);

                expect(menuOptions.filter("[data-type=data_source]")).not.toContain("a");
                expect(menuOptions.filter("[data-type=user]")).not.toContain("a");
                expect(menuOptions.filter("[data-type=workspace]")).not.toContain("a");
                expect(menuOptions.filter("[data-type=hdfs_entry]")).not.toContain("a");

                expect(menuOptions.filter("[data-type=attachment]")).toContain("a");
                expect(menuOptions.filter("[data-type=workfile]")).toContain("a");
                expect(menuOptions.filter("[data-type=dataset]")).toContain("a");
                expect(menuOptions.filter("[data-type=all]")).toContain("a");
            });

            it("has the 'this workspace' option in the 'Search in' menu", function() {
                var searchInMenu = this.page.$(".default_content_header .search_in");
                var searchInOptions = searchInMenu.find(".menu li");

                expect(searchInOptions.length).toBe(3);
                expect(searchInOptions).toContainTranslation("search.in.all");
                expect(searchInOptions).toContainTranslation("search.in.my_workspaces");
                expect(searchInOptions).toContainTranslation("search.in.this_workspace", { workspaceName: "Bob the workspace" });
                expect(searchInMenu.find(".chosen")).toContainTranslation("search.in.this_workspace", { workspaceName: "Bob the workspace" });
            });
        });

        context("when searching all of chorus", function() {
            beforeEach(function() {
                this.server.reset();
                this.page = new chorus.pages.WorkspaceSearchIndexPage(this.workspaceId, this.query);
                this.server.completeFetchFor(this.page.search, { thisWorkspace: { docs: [], numFound: 0 }});
                this.server.completeFetchFor(this.page.search.workspace(), { id: "101", name: "Bob the workspace" });
            });

            it("enables all options in the filter menu", function() {
                var menuOptions = this.page.$(".default_content_header li");

                expect(menuOptions.filter("[data-type=data_source]")).toContain("a");
                expect(menuOptions.filter("[data-type=user]")).toContain("a");
                expect(menuOptions.filter("[data-type=workspace]")).toContain("a");
                expect(menuOptions.filter("[data-type=hdfs_entry]")).toContain("a");
                expect(menuOptions.filter("[data-type=workfile]")).toContain("a");
                expect(menuOptions.filter("[data-type=dataset]")).toContain("a");
                expect(menuOptions.filter("[data-type=all]")).toContain("a");
            });
        });

        context("called resourcesLoaded only when both workspace and search fetches completes", function () {
            beforeEach(function () {
                this.server.completeFetchFor(this.page.search.workspace(), { id: "101", name: "Bob the workspace" });
            });

            it("doesn't create mainContentView", function () {
                expect(this.page.mainContent).toBeUndefined();
            });

            it("includes a section for every type of item when both fetches completes", function() {
                this.server.completeFetchFor(this.page.search, backboneFixtures.searchResult());

                var sections = this.page.$(".search_result_list ul");
                expect(sections.filter(".user_list.selectable")).toExist();
                expect(sections.filter(".workfile_list.selectable")).toExist();
                expect(sections.filter(".attachment_list.selectable")).toExist();
                expect(sections.filter(".workspace_list.selectable")).toExist();
                expect(sections.filter(".hdfs_entry_list.selectable")).toExist();
                expect(sections.filter(".data_source_list.selectable")).toExist();
            });

        });
    });

    it("sets the workspace id, for prioritizing search", function() {
        expect(this.page.workspaceId).toBe('101');
    });
});
