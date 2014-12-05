describe("chorus.views.SearchDataset", function() {
    beforeEach(function() {
        this.result = backboneFixtures.searchResult();
        this.result.set({query: "foo"});
        this.model = this.result.datasets().models[0];
        this.view = new chorus.views.SearchDataset({model: this.model});
        this.view.render();
    });

    describe("the 'found in workspaces' section", function() {
        beforeEach(function() {
            this.model.set({workspaces: [
                {
                    id: 10000,
                    name: "Foo"
                },
                {
                    id: 10010,
                    name: "Bar"
                },
                {
                    id: 10011,
                    name: "Baz"
                }
            ]});
            this.view.render();
        });

        it("should display a link to the first workspace", function() {
            expect(this.view.$(".location .found_in")).toContainTranslation("workspaces_used_in.body.other", {
                workspaceLink: "Foo",
                otherWorkspacesMenu: "2 other workspaces"
            });
        });

        it('should attach a data source to the database and data source links', function() {
            expect(this.view.$("a.data_source, a.database").data("data_source")).toBe(this.model.get("dataSource"));
        });
    });

    context("when the search results include a chorus view", function() {
        beforeEach(function() {
            this.model = backboneFixtures.workspaceDataset.chorusView({ workspace: { name: "Chorus View Thing" }, entitySubtype: "CHORUS_VIEW" });
            this.view = new chorus.views.SearchDataset({model: this.model});
            this.view.render();
        });

        it("should display a link to the single workspace", function() {
            expect(this.view.$(".location .found_in")).toContainTranslation("workspaces_used_in.body.one", {
                workspaceLink: "Chorus View Thing"
            });
        });

        it("links to the correct dataset url", function() {
            expect(this.view.$('.name').attr('href')).toMatch(/workspace/);
        });
    });

    context("when there is a table comment", function() {
        beforeEach(function() {
            this.model.set({'tableDescription': [{highlightedAttributes: {body: ['comment 1']}}]});
            this.view.render();
        });

        it("displays the table comment", function() {
            expect(this.view.$('.comment .comment_content')).toContainText('comment 1');
        });
    });

    it("displays the items name", function() {
        expect(this.view.$(".name")).toContainText(this.model.get("objectName"));
    });

    it("displays a link to the item", function() {
        expect(this.view.$(".name")).toHaveAttr("href", this.model.showUrl());
    });

    it("displays an icon for the item", function() {
        var img = this.view.$("img");
        expect(img).toExist();
        expect(img).toHaveAttr("src", this.model.iconUrl());
        expect(img).toHaveAttr("title", Handlebars.helpers.humanizedDatasetType(this.model.attributes));
    });

    itBehavesLike.ItPresentsModelWithTags();
});
