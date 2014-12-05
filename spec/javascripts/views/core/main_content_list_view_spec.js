describe("MainContentList", function() {
    beforeEach(function() {
        this.collection = backboneFixtures.userSet();
    });

    context("when no title override is provided", function() {
        beforeEach(function() {
            this.view = new chorus.views.MainContentList({ collection: this.collection, modelClass: "User" });
        });

        it("sets the title of the content header to the plural of the model class", function() {
            expect(this.view.contentHeader.options.title).toBe("Users");
        });

        context("emptyTitleBeforeFetch option set", function() {
            beforeEach(function() {
                this.view = new chorus.views.MainContentList({ collection: this.collection, modelClass: "User", emptyTitleBeforeFetch: true });
            });

            it("should not display the title", function() {
                expect(this.view.contentHeader.options.title).toBe(false);
            });
        });
    });

    it("doesn't re-render on collection change events", function() {
        var view = new chorus.views.MainContentList({ collection: this.collection, modelClass: "User" });
        spyOn(view, "preRender");
        this.collection.trigger('change');
        expect(view.preRender).not.toHaveBeenCalled();
    });

    context("when a title override is provided", function() {
        beforeEach(function() {
            this.view = new chorus.views.MainContentList({ collection: this.collection, modelClass: "User", title: "YES!" });
        });

        it("sets the title of the content header to the override", function() {
            expect(this.view.contentHeader.options.title).toBe("YES!");
        });
    });

    context("when a contentDetailsOptions hash is provided", function() {
        beforeEach(function() {
            this.view = new chorus.views.MainContentList({ collection: this.collection, modelClass: "User", contentDetailsOptions: {foo: "bar"} });
        });

        it("gets mixed in to the options for the list content details", function() {
            expect(this.view.contentDetails.options.foo).toBe("bar");
        });
    });

    context("when a contentOptions hash is provided", function() {
        beforeEach(function() {
            this.view = new chorus.views.MainContentList({ collection: this.collection, modelClass: "User", contentOptions: {foo: "bar"} });
        });

        it("gets mixed in to the content's options", function() {
            expect(this.view.content.options.collection).toEqual(this.collection);
            expect(this.view.content.options.foo).toEqual("bar");
        });
    });

    context("when no contentDetails is provided", function() {
        beforeEach(function() {
            this.view = new chorus.views.MainContentList({ collection: this.collection, modelClass: "User" });
        });

        it("creates a ListContentDetails view", function() {
            expect(this.view.contentDetails).toBeA(chorus.views.ListContentDetails);
        });
    });

    context("when a custom contentDetails is provided", function() {
        beforeEach(function() {
            this.contentDetails = stubView();
            this.view = new chorus.views.MainContentList({ collection: this.collection, modelClass: "User", contentDetails: this.contentDetails });
        });

        it("does not create a ListContentDetails view", function() {
            expect(this.view.contentDetails).not.toBeA(chorus.views.ListContentDetails);
        });

        it("uses the custom contentDetails", function() {
            expect(this.view.contentDetails).toBe(this.contentDetails);
        });

        it("does not construct a contentFooter", function() {
            expect(this.view.contentFooter).toBeUndefined();
        });
    });

    context("when persistent is passed as an option", function() {
        beforeEach(function() {
            this.view = new chorus.views.MainContentList({ persistent: true, collection: this.collection, modelClass: "User" });
        });

        it("sets persistent as a property of the view", function() {
            expect(this.view.persistent).toBeTruthy();
        });
    });

    context("when contentHeader is provided", function() {
        beforeEach(function() {
            this.contentHeader = stubView();
            this.view = new chorus.views.MainContentList({ contentHeader: this.contentHeader, collection: this.collection, modelClass: "User" });
        });

        it("uses the provided view", function() {
            expect(this.view.contentHeader).toBe(this.contentHeader);
        });
    });

    context("search option", function() {
        beforeEach(function() {
            this.searchOptions = {foo: "bar"};
            this.view = new chorus.views.MainContentList({
                collection: this.collection,
                modelClass: "User",
                search: this.searchOptions
            });
            this.view.render();
        });

        it("passes the search option to the list content details", function() {
            expect(this.view.contentDetails.options.search).toEqual({foo: "bar", list: $(this.view.content.el)});
        });
    });

    context("when useCustomList is true", function() {
        beforeEach(function() {
            this.view = new chorus.views.MainContentList({
                collection: backboneFixtures.schemaDatasetSet(),
                modelClass: "Dataset",
                useCustomList: true
            });
        });

        it("sets up a list based on the model class", function() {
            expect(this.view.content).toBeA(chorus.views.DatasetList);
        });
    });
});
