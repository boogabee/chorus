describe("chorus.router", function() {
    describe("generateRouteCallback", function() {
        beforeEach(function() {
            this.chorus = new window.Chorus();
            this.backboneSpy = spyOn(Backbone.history, "start");
            this.chorus.initialize();
            spyOn(this.chorus, "scrollToTop");
            spyOn(chorus.PageEvents, "off");
        });

        it("generates a new cachebuster value when navigating", function() {
            spyOn(this.chorus, "updateCachebuster").andCallThrough();
            this.chorus.router.navigate("login");
            expect(this.chorus.updateCachebuster).toHaveBeenCalled();
        });

        context("when navigating to a page that requires login", function() {
            beforeEach(function() {
                spyOn(this.chorus.router, "navigate").andCallThrough();
                spyOn(chorus.pages.UserNewPage.prototype, "initialize").andCallThrough();
                this.originalPageClass = chorus.pages.UserNewPage.prototype.pageClass;
                chorus.pages.UserNewPage.prototype.pageClass = "classyPage";
                spyOnEvent(this.chorus.router, "leaving");
                $("#jasmine_content").append("<div id='page'></div>");
                this.chorus.router.navigate("/users/new", { foo: "bar" });
            });

            afterEach(function() {
                chorus.pages.UserNewPage.prototype.pageClass = this.originalPageClass;
            });

            it("fetches the session", function() {
                expect(chorus.session).toHaveBeenFetched();
            });

            it("does not fetch the session if navigating after the session is already fetched", function() {
                this.server.lastFetch().succeed();
                this.server.reset();
                this.chorus.router.navigate("/users");
                expect(chorus.session).not.toHaveBeenFetched();
            });

            describe("when the session is valid", function() {
                beforeEach(function() {
                    this.server.lastFetch().succeed();
                });

                it("navigates to the requested page", function() {
                    expect(chorus.pages.UserNewPage.prototype.initialize).toHaveBeenCalled();
                });

                it("resets the PageEvents object", function() {
                    expect(chorus.PageEvents.off).toHaveBeenCalled();
                });

                it("scrolls to the top of the page", function() {
                    this.chorus.router.navigate("/users/new");
                    expect(this.chorus.scrollToTop).toHaveBeenCalled();
                });

                it("triggers the 'leaving' event on itself", function() {
                    expect("leaving").toHaveBeenTriggeredOn(this.chorus.router);
                });

                it("sets chorus.page.pageOptions to chorus.pageOptions", function() {
                    expect(this.chorus.page.pageOptions).toEqual({ foo: "bar" });
                    expect(this.chorus.pageOptions).toBeUndefined();
                });

                it("adds the page class to the #page", function() {
                    expect($("#page")).toHaveClass("classyPage");
                });
            });

            describe("when the session is invalid", function() {
                beforeEach(function() {
                    this.chorus.router.navigate.reset();
                    this.server.lastFetch().failUnauthorized();
                });

                it("navigates to login", function() {
                    expect(this.chorus.router.navigate).toHaveBeenCalledWith('login');
                });
            });
        });

        describe("when navigating to the login the page", function() {
            beforeEach(function() {
                spyOn(this.chorus.router, "navigate").andCallThrough();
                spyOn(chorus.pages.LoginPage.prototype, "initialize").andCallThrough();
            });

            context("when the user is already logged in", function() {
                beforeEach(function() {
                    spyOn(this.chorus.session, "loggedIn").andReturn(true);
                    this.chorus.router.navigate("login");
                });

                it("redirects them to their dashboard", function() {
                    expect(this.chorus.router.navigate).toHaveBeenCalledWith("");
                });
            });

            context("when the user is not logged in", function() {
                beforeEach(function() {
                    spyOn(this.chorus.session, "loggedIn").andReturn(false);
                    this.chorus.router.navigate("login");
                });

                it("goes to the login page", function() {
                    expect(chorus.pages.LoginPage.prototype.initialize).toHaveBeenCalled();
                });
            });
        });
    });

    describe("#navigate", function() {
        beforeEach(function() {
            spyOn(Backbone.history, "loadUrl").andCallThrough();
            spyOn(Backbone.history, "navigate").andCallThrough();
            this.chorus = new window.Chorus();
            this.backboneSpy = spyOn(Backbone.history, "start");
            this.chorus.initialize();
            var session = this.chorus.session;
            spyOn(this.chorus.session, "fetch").andCallFake(function(options) {
                options.success(session, { status: "ok" });
            });
        });

        it("renders the page with parameters", function() {
            this.chorus.router.navigate("/workspaces/5");
            expect(this.chorus.page.model.get("id")).toBe("5");
        });

        it("closes the current modal", function() {
            this.chorus.modal = new chorus.dialogs.ChangePassword();
            spyOn(this.chorus.modal, "closeModal");
            this.chorus.router.navigate("/");
            expect(this.chorus.modal.closeModal).toHaveBeenCalled();
        });

        it("sets chorus.pageOptions to the second argument", function() {
            this.chorus.router.navigate("/workspaces/5", {foo: "bar"});
            expect(this.chorus.page.pageOptions).toEqual({foo: "bar"});
        });

        describe("when a current fragment is set", function() {
            beforeEach(function() {
                Backbone.history.fragment = "foo";
            });

            describe("and the target fragment is not the current fragment", function() {
                it("calls Backbone's navigate with {trigger: true} when pageOptions is undefined", function () {
                    this.chorus.router.navigate("/bar");
                    expect(Backbone.history.navigate).toHaveBeenCalledWith("/bar", {trigger: true});
                });

                it("calls Backbone's navigate with the given trigger value when pageOptions is defined", function () {
                    this.chorus.router.navigate("/bar", {foo: "bar", trigger: false});
                    expect(Backbone.history.navigate).toHaveBeenCalledWith("/bar", {foo: "bar", trigger: false});
                });
            });

            describe("and the target fragment is the current fragment", function() {
                it("calls loadUrl on the fragment", function() {
                    this.chorus.router.navigate("/foo");
                    expect(Backbone.history.navigate).not.toHaveBeenCalled();
                    expect(Backbone.history.loadUrl).toHaveBeenCalledWith("/foo");
                });

                it("calls loadUrl on the fragment, even if the target fragment is prefixed by #", function() {
                    this.chorus.router.navigate("#/foo");
                    expect(Backbone.history.navigate).not.toHaveBeenCalled();
                    expect(Backbone.history.loadUrl).toHaveBeenCalledWith("/foo");
                });
            });

            describe("when the fragment is URI encoded", function() {
                beforeEach(function() {
                    Backbone.history.fragment = "foo/'1'|2";
                });

                describe("and the target fragment is the current fragment", function() {
                    it("calls loadUrl on the fragment", function() {
                        this.chorus.router.navigate("/foo/%271%27%7C2");
                        expect(Backbone.history.loadUrl).toHaveBeenCalledWith("/foo/%271%27%7C2");
                        expect(Backbone.history.navigate).not.toHaveBeenCalled();
                    });

                    it("calls loadUrl on the fragment, even if the target fragment is prefixed by #", function() {
                        this.chorus.router.navigate("#/foo/%271%27%7C2");
                        expect(Backbone.history.loadUrl).toHaveBeenCalledWith("/foo/%271%27%7C2");
                        expect(Backbone.history.navigate).not.toHaveBeenCalled();
                    });
                });
            });
        });
    });

    describe("when there is an alternate home page", function () {
        beforeEach(function () {
            spyOn(chorus.models.Config.instance().license(), 'homePage').andReturn("UserIndex");
            this.chorus = new window.Chorus();
            this.backboneSpy = spyOn(Backbone.history, "start");
            this.chorus.initialize();
            var session = this.chorus.session;
            spyOn(this.chorus.session, "fetch").andCallFake(function(options) {
                options.success(session, { status: "ok" });
            });
        });

        it("uses the alternate home page", function() {
            this.chorus.router.navigate("");
            expect(this.chorus.page).toBeA(chorus.pages.UserIndexPage);
        });
    });

    describe("when there is not an alternate home page", function () {
        beforeEach(function () {
            spyOn(chorus.models.Config.instance().license(), 'homePage').andReturn(null);
            this.chorus = new window.Chorus();
            this.backboneSpy = spyOn(Backbone.history, "start");
            this.chorus.initialize();
            var session = this.chorus.session;
            spyOn(this.chorus.session, "fetch").andCallFake(function(options) {
                options.success(session, { status: "ok" });
            });
        });

        it("uses the Dashboard page", function() {
            this.chorus.router.navigate("");
            expect(this.chorus.page).toBeA(chorus.pages.DashboardPage);
        });
    });

    describe("#reload", function() {
        it("navigates to the current url fragment", function() {
            Backbone.history.fragment = '/somewhere';
            spyOn(chorus.router, 'navigate');
            chorus.router.reload();
            expect(chorus.router.navigate).toHaveBeenCalledWith(Backbone.history.fragment);
        });
    });

    describe("url decoding", function() {
        beforeEach(function() {
            setLoggedInUser();
            this.chorus = new window.Chorus();
            this.backboneSpy = spyOn(Backbone.history, "start");
            this.chorus.initialize();
            var session = this.chorus.session;
            spyOn(this.chorus.session, "fetch").andCallFake(function(options) {
                options.success(session, { status: "ok" });
            });

            spyOn(chorus.pages.SearchIndexPage.prototype, "setup").andCallThrough();
        });

        it("does not decode fragments before matching routes", function() {
            this.chorus.router.navigate('/search/has%2Fslash');
            expect(chorus.pages.SearchIndexPage.prototype.setup).toHaveBeenCalled();
        });

        it("decodes parameters before constructing pages", function() {
            this.chorus.router.navigate('/search/has%2Fslash');
            expect(chorus.pages.SearchIndexPage.prototype.setup).toHaveBeenCalledWith('has/slash');
        });
    });
});
