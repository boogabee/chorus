describe("chorus.pages.WorkFlowShowPage", function() {
    function pollFor (conditionFunc, done) {
        var interval = jasmine.getEnv().clock.setInterval(function () {
            if (conditionFunc()) {
                clearInterval(interval);
                done();
            }
        }, 100);
    }

    beforeEach(function() {
        this.page = new chorus.pages.WorkFlowShowPage('4');
        setLoggedInUser();
        this.page.render();  //normally done in the router
    });

    context("when the workfile is loaded", function() {
        beforeEach(function() {
            this.workfile = backboneFixtures.workfile.alpine({id: 4});
            this.workfile.urlParams = {connect: true};
            this.server.completeFetchFor(this.workfile);
        });

        it("fetches the workfile for the workflow", function() {
            expect(this.page.model).toBeA(chorus.models.AlpineWorkfile);
            expect(this.page.model.get("id")).toBe(4);
            expect(this.page.model).toHaveBeenFetched();
        });

        it("does not render the breadcrumbs", function() {
            expect(this.page.$(".breadcrumbs")).not.toExist();
        });

        it("has an iframe to alpine", function() {
            expect(this.page.$("iframe").attr("src")).toBe(this.workfile.iframeUrl());
        });

        context("when receiving a 'go_to_workfile' message", function() {
            beforeEach(function (done) {
                this.routerSpy = spyOn(chorus.router, 'navigate');
                window.postMessage({action: 'go_to_workfile'}, '*');
                pollFor(_.bind(function () {
                    return (this.routerSpy.calls.count() > 0);
                }, this), done);
            });

            it("routes to the workflow show page", function() {
                expect(this.routerSpy).toHaveBeenCalledWith(this.workfile.showUrl());
            });
        });

        context("trying to navigate", function() {
            beforeEach(function() {
                $("#jasmine_content").append(this.page.$el);
                this.iframeWindow = this.page.$("iframe#alpine")[0].contentWindow;
                spyOn(this.iframeWindow, "postMessage").andCallThrough();
            });

            context("clicking an internal link on the header", function() {
                beforeEach(function() {
                    this.event = jQuery.Event("click");
                    spyOn(this.event, "preventDefault");
                    this.page.$("a[href='#/']").trigger(this.event);
                });

                it("does not navigate away", function() {
                    expect(this.event.preventDefault).toHaveBeenCalled();
                });

                it("stores the intended href", function() {
                    expect(this.page.intendedHref).toBeDefined();
                    expect(this.page.intendedHref).toBe("#/");
                });

                it("publishes an 'intent_to_close' message", function() {
                    expect(this.iframeWindow.postMessage).toHaveBeenCalledWith({action: "intent_to_close"}, "*");
                });
            });

            context("clicking a link that should open a new tab on the header", function() {
                beforeEach(function() {
                    this.event = jQuery.Event("click");
                    spyOn(this.event, "preventDefault");
                    this.page.$(".header").append('<a href="http://github.com/Chorus" target="_blank"></a>');
                    this.page.$("a[href='http://github.com/Chorus']").trigger(this.event);
                });

                it("does not block the event", function() {
                    expect(this.event.preventDefault).not.toHaveBeenCalled();
                });

                it("does not store the intended href", function() {
                    expect(this.page.intendedHref).not.toBeDefined();
                });

                it("does not publishes an 'intent_to_close' message", function() {
                    expect(this.iframeWindow.postMessage).not.toHaveBeenCalled();
                });
            });

            context("searching through the header", function() {

                itBehavesLike.standardWorkflowShowPageSearch = function() {
                    context("when selecting an item and hitting the enter key", function() {
                        beforeEach(function() {
                            var searchInput = this.page.$(".search input");
                            searchInput.val("sfo");
                            searchInput.trigger("keydown");
                            searchInput.trigger("keyup");
                            this.server.lastFetch().succeed(backboneFixtures.typeAheadSearchResult());

                            searchInput.trigger(jQuery.Event("keydown", {keyCode: 40}));
                            searchInput.trigger(jQuery.Event("keyup", {keyCode: 40}));
                            searchInput.trigger(jQuery.Event("keydown", {keyCode: 40}));
                            searchInput.trigger(jQuery.Event("keyup", {keyCode: 40}));

                            this.event = jQuery.Event("keydown", {keyCode: 13});
                            spyOn(this.event, "preventDefault");
                            spyOn(chorus.router, "navigate");
                            searchInput.trigger(this.event);
                        });

                        it("does not navigate away", function() {
                            expect(chorus.router.navigate).not.toHaveBeenCalled();
                            expect(this.event.preventDefault).toHaveBeenCalled();
                        });

                        it("stores the intended href", function() {
                            expect(this.page.intendedHref).toBeDefined();
                            expect(this.page.intendedHref).toBe(this.page.$(".type_ahead_search li.selected a").attr("href"));
                        });

                        it("publishes an 'intent_to_close' message", function() {
                            expect(this.iframeWindow.postMessage).toHaveBeenCalledWith({action: "intent_to_close"}, "*");
                        });
                    });

                    context("when hitting any other key", function() {
                        beforeEach(function() {
                            this.event = jQuery.Event("keydown", {keyCode: 32});
                            spyOn(this.event, "preventDefault");
                            this.page.$(".search input").val("sfo");
                            this.page.$(".search input").trigger(this.event);
                        });

                        it("allows the event to happen", function() {
                            expect(this.event.preventDefault).not.toHaveBeenCalled();
                        });
                    });
                };

                context("when full search is enabled", function() {

                    itBehavesLike.standardWorkflowShowPageSearch();

                    context("when hitting the enter key", function() {
                        beforeEach(function() {
                            this.event = jQuery.Event("keydown", {keyCode: 13});
                            spyOn(this.event, "preventDefault");
                            this.page.$(".search input").val("sfo");
                            this.page.$(".search input").trigger(this.event);
                        });

                        it("does not navigate away", function() {
                            expect(this.event.preventDefault).toHaveBeenCalled();
                        });

                        it("stores the intended href", function() {
                            expect(this.page.intendedHref).toBeDefined();
                            expect(this.page.intendedHref).toBe("#/search/sfo");
                        });

                        it("publishes an 'intent_to_close' message", function() {
                            expect(this.iframeWindow.postMessage).toHaveBeenCalledWith({action: "intent_to_close"}, "*");
                        });
                    });
                });

                context("when full search is disabled", function() {
                    beforeEach(function () {
                        spyOn(chorus.models.Config.instance().license(), "limitSearch").andReturn(true);
                    });

                    itBehavesLike.standardWorkflowShowPageSearch();

                    context("when hitting the enter key", function() {
                        beforeEach(function() {
                            this.event = jQuery.Event("keydown", {keyCode: 13});
                            spyOn(this.event, "preventDefault");
                            this.page.$(".search input").val("sfo");
                            this.page.$(".search input").trigger(this.event);
                        });

                        it("does not publish an 'intent_to_close' message", function() {
                            expect(this.iframeWindow.postMessage).not.toHaveBeenCalled();
                        });
                    });
                });
            });

            context("receiving a 'allow_close' message", function() {
                beforeEach(function(done) {
                    this.page.intendedHref = "#/a_url";
                    this.routerSpy = spyOn(chorus.router, 'navigate');
                    window.postMessage({action: 'allow_close'}, '*');

                    pollFor(_.bind(function () {
                        return (this.routerSpy.calls.count() > 0);
                    }, this), done);
                });

                it("navigates to the stored intended href", function() {
                    expect(this.routerSpy).toHaveBeenCalledWith("#/a_url");
                });
            });
        });
    });

    context("when the workfile is not loaded", function() {
        it("does not display garbage on Alpine", function() {
            expect(this.page.$("iframe").attr("src")).toBe("");
        });
    });

    context("when the workfile is not accessible", function() {
        it("handles the error", function() {
            spyOn(Backbone.history, "loadUrl");
            this.page.model.serverErrors = {
                modelData: { }
            };
            this.page.model.trigger("resourceForbidden");
            expect(Backbone.history.loadUrl).toHaveBeenCalled();
        });
    });

    context("when the workfile has errors", function() {
        context("when the errors come from the workspace", function() {
            it("does the normal thing", function() {
                spyOn(Backbone.history, "loadUrl");
                this.page.model.serverErrors = {
                    record: 'CHEESE',
                    modelData: {
                        entityType: 'workspace'
                    }
                };
                this.page.model.trigger("resourceForbidden");
                expect(Backbone.history.loadUrl).toHaveBeenCalled();
            });
        });

        context("when the errors come from the data source", function() {
            it("handles the workfile errors", function() {
                spyOn(this.page, "launchDataSourceAccountDialog");
                this.page.model.serverErrors = {
                    record: 'CHEESE',
                    modelData: {
                        entityType: 'data_source'
                    }
                };
                this.page.model.trigger("resourceForbidden");
                expect(this.page.launchDataSourceAccountDialog).toHaveBeenCalled();
            });

            context("when receiving an 'unauthorized' message", function () {
                beforeEach(function (done) {
                    spyOn(chorus, 'requireLogin');
                    expect(chorus.requireLogin).not.toHaveBeenCalled();
                    window.postMessage({action: 'unauthorized'}, '*');

                    // times out if requireLogin never called
                    pollFor(function () {
                        return (chorus.requireLogin.calls.count() > 0 );
                    }, done);
                });

                it("routes to the login page", function() {
                    expect(chorus.requireLogin.calls.count()).toBeGreaterThan(0);
                });
            });
        });
    });
});
