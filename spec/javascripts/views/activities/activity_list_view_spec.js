describe("chorus.views.ActivityList", function() {
    beforeEach(function() {
        this.collection = new chorus.collections.ActivitySet([]);
        this.collection.reset([
            backboneFixtures.activity.dataSourceCreated(),
            backboneFixtures.activity.dataSourceCreated()
        ]);
        this.collection.loaded = true;
        this.view = new chorus.views.ActivityList({collection: this.collection, additionalClass: "foo_class", type: "Foo"});
    });

    describe("pageEvent subscriptions", function() {
        beforeEach(function() {
            this.note = backboneFixtures.activity.noteOnGreenplumDataSource();
            this.collection.add(this.note);
            this.view.render();
        });

        it("re-fetches the collection when 'note:deleted' is fired", function() {
            this.server.reset();
            chorus.PageEvents.trigger('note:deleted', this.note);
            expect(this.server.lastFetchFor(this.collection)).toBeDefined();
        });

        it('re-renders when note:saved is fired', function() {
            this.newNote = backboneFixtures.activity.noteOnGreenplumDataSource({id: this.note.id, body: 'A New Note'});
            chorus.PageEvents.trigger('note:saved', this.newNote);
            expect(this.view.$("li[data-activity-id=" + this.note.id + "]")).toContainText("A New Note");
        });
    });

    describe("#render", function() {
        beforeEach(function() {
            this.view.render();
        });

        it("adds additionalClass to the top-level element", function() {
            expect($(this.view.el)).toHaveClass("foo_class");
        });

        it("renders an li for each item in the collection", function() {
            expect(this.view.$("li[data-activity-id]").length).toBe(this.collection.length);
        });

        it("cleans up old activity views", function() {
            var tornDown = false;
            spyOn(this.view.activities[0], "teardown").andCallFake(function() {tornDown = true;});
            this.view.render();
            expect(tornDown).toBeTruthy();
        });

        it("registers ActivityViews as subviews", function() {
            var activities = this.view.activities;
            expect(this.view.getSubViews().length).toBeGreaterThan(0);
            expect(_.intersection(this.view.getSubViews(), activities)).toEqual(activities);
        });

        describe("when there are no activity items", function() {
            context("and there is an type", function() {
                beforeEach(function() {
                    this.collection.reset([]);
                    this.view.render();
                });

                it("displays the 'no notes' message", function() {
                    expect(this.view.$("ul.activities li")).not.toExist();
                    expect(this.view.$(".no_items")).toContainTranslation("activity.none", {type: "Foo"});
                });
            });

            context("and there is no type", function() {
                beforeEach(function() {
                    delete this.view.options.type;
                    this.collection.reset([]);
                    this.view.render();
                });

                it("displays the 'no notes' message", function() {
                    expect(this.view.$("ul.activities li")).not.toExist();
                    expect(this.view.$(".no_items")).toContainTranslation("activity.no_recent");
                });
            });
        });

        describe("comment rendering", function() {
            beforeEach(function() {
                spyOn(chorus, "cachebuster").andReturn(555);
                var comments = this.collection.at(0).comments();
                comments.add([
                    new chorus.models.Comment({
                        author: {
                            id: 10101,
                            fullName: "John Commenter"
                        },
                        text: 'I love you all'
                    }),
                    new chorus.models.Comment({
                        author: {
                            id: 10102
                        },
                        text: 'I love you all'
                    }),
                    new chorus.models.Comment({
                        author: {
                            id: 10103
                        },
                        text: 'I love you all'
                    })
                ]);

                this.view.render();
            });

            describe("when the more link is clicked", function() {
                beforeEach(function() {
                    spyOn(chorus.PageEvents, "trigger");
                    this.view.$("li[data-activity-id]:eq(0) .comments a.more").click();
                });

                it("adds the 'more' class to the comments section", function() {
                    expect(this.view.$("li[data-activity-id]:eq(0) .comments")).toHaveClass("more");
                });

                it("triggers a content:changed event", function() {
                    expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("content:changed");
                });

                describe("when the less link is clicked", function() {
                    beforeEach(function() {
                        resetBackboneEventSpies(this.view);
                        this.view.$("li[data-activity-id]:eq(0) .comments a.less").click();
                    });

                    it("removes the 'more' class to the comments section", function() {
                        expect(this.view.$("li[data-activity-id]:eq(0) .comments")).not.toHaveClass("more");
                    });

                    it("triggers a content:changed event", function() {
                        expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("content:changed");
                    });
                });
            });
        });

        describe("pagination", function() {
            function itDoesNotShowAMoreLink() {
                it("does not render a 'more' link", function() {
                    expect(this.view.$("a.more_items")).not.toExist();
                });
            }

            function itShowsAMoreLink(nextPage) {
                it("renders a 'more' link", function() {
                    expect(this.view.$(".more_items a")).toExist();
                });

                describe("when the 'more' link is clicked", function() {
                    beforeEach(function() {
                        this.originalActivityCount = this.view.$('li[data-activity-id]').length;
                        spyOn(this.view, 'postRender').andCallThrough();
                        this.view.$(".more_items a").click();

                        this.server.completeFetchFor(this.collection, [
                            backboneFixtures.activity.dataSourceCreated(),
                            backboneFixtures.activity.dataSourceCreated(),
                            backboneFixtures.activity.dataSourceCreated()
                        ], { page: nextPage });
                    });

                    it("fetches the next page of the activity stream", function() {
                        expect(this.view.$('li[data-activity-id]').length).toBe(this.originalActivityCount + 3);
                    });

                    it("only re-renders the page once", function() {
                        expect(this.view.postRender.calls.count()).toBe(1);
                    });
                });
            }

            context("with full pagination information in the response", function() {
                beforeEach(function() {
                    this.collection.pagination = {};
                    this.collection.pagination.total = "1";
                    this.collection.pagination.page = "1";
                    this.collection.pagination.records = "8";
                    this.view.render();
                });

                context("when there is no next page", function() {
                    itDoesNotShowAMoreLink();
                });

                context("when there is a next page", function() {
                    beforeEach(function() {
                        this.collection.pagination.total = "4";
                        this.view.render();
                    });

                    itShowsAMoreLink(2);
                });
            });
        });
    });

    describe("error handling", function() {
        beforeEach(function() {
            spyOn(chorus, "log");
            spyOn(this.collection.at(0), 'get').andCallFake(function() {throw 'an error during rendering';});
        });

        it("does not raise an exception", function() {
            this.view.render();
        });

        it("logs the exception", function() {
            this.view.render();
            expect(chorus.log).toHaveBeenCalled();
        });

        it("should show toast message for bad activity in dev mode", function() {
            spyOn(chorus, "toast");
            chorus.isDevMode.andReturn(true);
            this.view.render();
            expect(chorus.toast).toHaveBeenCalled();
        });
        
        it ("should not show toast message for bad activity in non dev mode", function() {
            spyOn(chorus, "toast");
            chorus.isDevMode.andReturn(false);
            this.view.render();
            expect(chorus.toast).not.toHaveBeenCalled();
        });
    });

    describe("#show", function() {
        beforeEach(function() {
            this.view.render();
            expect(this.view.activities.length).toBe(this.collection.length);
            _.each(this.view.activities, function(activity) {
                spyOn(activity, "show");
            });
            this.view.show();
        });

        it("calls show on each activity", function() {
            _.each(this.view.activities, function(activity) {
                expect(activity.show).toHaveBeenCalled();
            });
        });
    });
});
