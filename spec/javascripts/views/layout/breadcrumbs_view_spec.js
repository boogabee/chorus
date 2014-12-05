describe("chorus.views.BreadcrumbView", function() {
    describe("#render", function() {
        beforeEach(function() {
            this.dataObject = {foo: "bar"};
            this.crumbsArray = [
                {label : "Home", url : "#/"},
                {label : "Foo", url : "#/foo"},
                {label : "Bar"}
            ];
        });

        context("when crumbs is an array", function() {
            beforeEach(function() {
                this.view = new chorus.views.BreadcrumbsView({ breadcrumbs : this.crumbsArray });
                this.view.render();
            });

            it("renders the breadcrumbs", function() {
                expect(this.view.$(".breadcrumb").length).toBe(3);
            });

            it("renders a link to all breadcrumbs except the last one", function() {
                expect(this.view.$(".breadcrumb a").length).toBe(2);
            });

            it("renders links to breadcrumbs", function() {
                expect(this.view.$(".breadcrumb:eq(0) a").attr("href")).toBe("#/");
                expect(this.view.$(".breadcrumb:eq(1) a").attr("href")).toBe("#/foo");
            });

            it("sets title attributes", function() {
                expect(this.view.$(".breadcrumb:eq(0) a").attr("title")).toBe("Home");
                expect(this.view.$(".breadcrumb:eq(1) a").attr("title")).toBe("Foo");
                expect(this.view.$(".breadcrumb:eq(2) span").attr("title")).toBe("Bar");
            });
        });

        context("when crumbs is a function", function() {
            beforeEach(function() {
                this.view = new chorus.views.BreadcrumbsView({ breadcrumbs :
                    _.bind(function() {
                        return this.crumbsArray;
                    }, this)
                });
                this.view.render();
            });

            it("renders the breadcrumbs", function() {
                expect(this.view.$(".breadcrumb").length).toBe(3);
            });
        });
    });
});
