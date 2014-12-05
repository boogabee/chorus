describe("ListHeaderView", function() {
    beforeEach(function() {
        this.view = new chorus.views.ListHeaderView({
            title: "Hi there",
            linkMenus: {
                my_menu: {
                    title: "Title",
                    options: [
                        {data: "", text: "All"},
                        {data: "sql", text: "SQL"}
                    ],
                    event: "filter"
                }
            }
        });
    });

    describe("#render", function() {
        beforeEach(function() {
            this.view.render();
        });

        it("renders link menus", function() {
            expect(this.view.$(".menus ul[data-event=filter]")).toExist();
        });

        it("renders the header title", function() {
            expect(this.view.$("h1").text().trim()).toBe("Hi there");
            expect(this.view.$("h1").attr("title")).toBe("Hi there");
        });

        it("does not render an image", function() {
            expect(this.view.$(".icon")).not.toExist();
        });

        it("adds a class based on the key in the linkMenu's hash", function() {
            expect(this.view.$('.menus > .my_menu')).toExist();
        });

        it("doesn't render the sandbox location", function() {
            expect(this.view.$(".found_in")).not.toExist();
        });

        context("when an imageUrl is provided", function() {
            beforeEach(function() {
                this.view.options.imageUrl = "image/foo/bar.png";
                this.view.render();
            });

            it("renders the image", function() {
                expect(this.view.$(".icon")).toHaveAttr("src", "image/foo/bar.png");
            });

            context("and an imageTitle is provided", function() {
                beforeEach(function() {
                    this.view.options.imageTitle = "a title";
                    this.view.render();
                });

                it("sets the title on the image", function() {
                    expect(this.view.$(".icon")).toHaveAttr("title", "a title");
                });
            });
        });

        context("when sandbox is provided", function() {
            beforeEach(function() {
                this.workspace = backboneFixtures.workspace();
                this.view.options.sandbox = this.workspace.sandbox();
                this.view.render();
            });
            it("shows the location of the sandbox", function() {
                expect(this.view.$(".found_in").text()).not.toBeEmpty();
                expect(this.view.$(".found_in a").eq(0).text()).toBe(this.workspace.sandbox().dataSource().name());
                expect(this.view.$(".found_in a").eq(1).text()).toBe(this.workspace.sandbox().database().name());
                expect(this.view.$(".found_in a").eq(2).text()).toBe(this.workspace.sandbox().schema().name());
            });
        });

        context("when sandbox is provided", function() {
            beforeEach(function() {
                this.workspace = backboneFixtures.workspace();
                this.view.options.sandbox = this.workspace.sandbox();
                this.view.render();
            });
            it("shows the location of the sandbox", function() {
                expect(this.view.$(".found_in").text()).not.toBeEmpty();
                expect(this.view.$(".found_in a").eq(0).text()).toBe(this.workspace.sandbox().dataSource().name());
                expect(this.view.$(".found_in a").eq(1).text()).toBe(this.workspace.sandbox().database().name());
                expect(this.view.$(".found_in a").eq(2).text()).toBe(this.workspace.sandbox().schema().name());
            });
        });
    });

    describe("event propagation", function() {
        beforeEach(function() {
            this.view.render();
        });

        it("propagates choice events as choice: events", function() {
            this.choiceSpy = jasmine.createSpy("choice:filter");
            this.view.bind("choice:filter", this.choiceSpy);
            this.view.$("li[data-type=sql] a").click();
            expect(this.choiceSpy).toHaveBeenCalledWith("sql");
        });
    });
});
