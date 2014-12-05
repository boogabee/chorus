describe("chorus.pages.UserShow", function() {
    describe("#setup", function() {
        beforeEach(function() {
            this.page = new chorus.pages.UserShowPage("44");
        });

        it("sets up the model with the supplied user id", function() {
            expect(this.page.model.get("id")).toBe("44");
        });

        it("fetches the model automatically", function() {
            expect(_.any(this.server.requests, function(req) { return req.url.trim() === "/users/44"; })).toBeTruthy();
        });

        it("has a helpId", function() {
            expect(this.page.helpId).toBe("user");
        });

        context("when the model fails to load properly", function() {
            beforeEach(function() {
                spyOn(Backbone.history, "loadUrl");
                this.page.model.trigger('resourceNotFound');
            });

            it("navigates to the 404 page", function() {
                expect(Backbone.history.loadUrl).toHaveBeenCalledWith("/invalidRoute");
            });
        });
    });

    describe("#render", function() {
        beforeEach(function() {
            this.user = backboneFixtures.user({username: "edcadmin", id: "42", firstName: "EDC", lastName: "Admin"});
            this.page = new chorus.pages.UserShowPage(this.user.get("id"));
            this.server.completeFetchFor(this.user);
        });

        it("displays the first + last name in the header", function() {
            expect(this.page.$(".content_header h1").text().trim()).toBe("EDC Admin");
        });

        it("displays the word 'details' in the details-header", function() {
            expect(this.page.$(".content_details").text().trim()).toBe(t("users.details"));
        });

        it("displays a tag box", function() {
            expect(this.page.$(".content_header .tag_box")).toExist();
        });

        context("breadcrumbs", function() {
            it("links to home for the first crumb", function() {
                expect(this.page.$("#breadcrumbs .breadcrumb a").eq(0).attr("href")).toBe("#/");
                expect(this.page.$("#breadcrumbs .breadcrumb a").eq(0).text()).toBe(t("breadcrumbs.home"));
            });

            it("links to /users for the second crumb", function() {
                expect(this.page.$("#breadcrumbs .breadcrumb a").eq(1).attr("href")).toBe("#/users");
                expect(this.page.$("#breadcrumbs .breadcrumb a").eq(1).text()).toBe(t("breadcrumbs.users"));
            });

            it("displays the user name for the last crumb", function() {
                expect(this.page.$("#breadcrumbs .breadcrumb .slug").text()).toBe("EDC Admin");
            });
        });
    });

    context("sidebar", function() {
        beforeEach(function() {
            setLoggedInUser();
        });

        context("on your own page", function() {
            beforeEach(function() {
                this.page = new chorus.pages.UserShowPage(chorus.session.user().id.toString());
                this.server.completeFetchFor(this.page.model);
            });
        });

        context("not on your own page", function() {
            beforeEach(function() {
                this.page = new chorus.pages.UserShowPage('42');
                this.server.completeFetchFor(this.page.model);
                expect(chorus.session.user().id).not.toEqual(42);
            });

            it("puts a UserSidebar in the sidebar", function() {
                expect(this.page.sidebar).toBeA(chorus.views.UserSidebar);
            });

            it("sets the sidebar's model to the user", function() {
                expect(this.page.sidebar.model).toBe(this.page.model);
            });
        });
    });
});
