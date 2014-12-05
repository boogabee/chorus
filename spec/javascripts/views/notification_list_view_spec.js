describe("chorus.views.NotificationList", function() {
    beforeEach(function() {
        this.collection = backboneFixtures.notificationSet();
        this.collection.comparator = function(notification) {
            notification.get("id");
        };
        this.collection.sort();
        this.view = new chorus.views.NotificationList({ collection: this.collection });
    });

    describe("#render", function() {
        beforeEach(function() {
            this.collection.loaded = true;
            spyOn(chorus.views.Activity.prototype, 'initialize').andCallThrough();
            this.view.render();
        });

        it("renders an li for each notification in the collection", function() {
            expect(this.view.$("li.activity").length).toBe(backboneFixtures.notificationSet().length);
        });

        it("does not render the links section in the handlebars template", function() {
            expect(this.view.$('li').find('.comment').length).toEqual(0);
            expect(this.view.$('li').find('.publish').length).toEqual(0);
        });

        it("highlights the unread notifications", function() {
            this.collection.each(function(model, i) {
                if (model.get("unread")) {
                    expect(this.view.$("li.activity:eq("+i+")")).toHaveClass("unread");
                } else {
                    expect(this.view.$("li.activity:eq("+i+")")).not.toHaveClass("unread");
                }
            }, this);
        });

        it("passes the 'isNotification' option to the activity views", function() {
            var viewOptions = chorus.views.Activity.prototype.initialize.lastCall().args[0];
            expect(viewOptions.isNotification).toBeTruthy();
        });

        it("passes the 'isReadOnly' option to the activity views", function() {
            var viewOptions = chorus.views.Activity.prototype.initialize.lastCall().args[0];
            expect(viewOptions.isReadOnly).toBeTruthy();
        });
    });

    describe("error handling bad notifications", function() {
        beforeEach(function() {
            spyOn(chorus, 'log');
            var brokenNotification = new chorus.models.Notification();
            brokenNotification.set({ action: "IMPORT_SUCCESS" });
            this.collection.add(brokenNotification);
            this.collection.sort();
            this.collection.loaded = true;
            spyOn(chorus.views.Activity.prototype, 'initialize').andCallThrough();
        });

        it("should show toast message for broken notifications in dev mode", function() {
            spyOn(chorus, "toast");
            chorus.isDevMode.andReturn(true);
            this.view.render();
            expect(chorus.toast).toHaveBeenCalled();
        });

        it ("should not show toast message for broken activities in non dev mode", function() {
            spyOn(chorus, "toast");
            chorus.isDevMode.andReturn(false);
            this.view.render();
            expect(chorus.toast).not.toHaveBeenCalled();
        });

        it("logs stuff about the broken notification", function() {
            expect(chorus.log).toHaveBeenCalled();
            expect(chorus.log.lastCall().args[3]).toBe(this.collection.at(this.collection.length-1));
        });
    });

    describe("more link", function() {
        beforeEach(function() {
            this.collection.loaded = true;
            this.collection.pagination = (this.collection.pagination || {});
            this.collection.pagination.page = "1";
            this.collection.pagination.total = "99999999";
        });

        context("when options.allowMoreLink is false", function() {
            beforeEach(function() {
                this.view.options.allowMoreLink = false;
                this.view.render();
            });

            it("hides the more link", function() {
                expect(this.view.$(".more_items a")).not.toExist();
            });
        });

        context("when options.allowMoreLink is true", function() {
            beforeEach(function() {
                this.view.options.allowMoreLink = true;
                this.view.render();
            });

            context("when more results are available", function() {
                it("shows the more link", function() {
                    expect(this.view.$(".more_items a")).toExist();
                });

                context("clicking the more link", function() {
                    beforeEach(function() {
                        this.view.$(".more_items a").click();
                    });

                    it("loads more results", function() {
                        expect(this.server.lastFetch().params().page).toBe("2");
                    });

                    context("when the fetch completes", function() {
                        beforeEach(function() {
                            this.newModel = backboneFixtures.notificationSet().at(3);
                            this.newModel.set('id', _.uniqueId('xx'));
                            this.newModel.set('cid', _.uniqueId('rr'));

                            spyOn(chorus.collections.NotificationSet.prototype, "markAllRead").andCallThrough();
                            this.server.completeFetchFor(this.collection, [this.newModel], {page:2}, {page: "2", total: "9999999"});
                        });

                        it("renders the new notifications", function() {
                            expect(this.view.$("li.activity").length).toBe(backboneFixtures.notificationSet().length + 1);
                        });

                        it("marks all notification read again", function() {
                            expect(chorus.collections.NotificationSet.prototype.markAllRead).toHaveBeenCalled();
                        });

                        context("clicking the more link again", function() {
                            beforeEach(function() {
                                expect(this.view.$(".more_items a")).toExist();
                                this.view.$(".more_items a").click();
                            });

                            it("marks everything read again", function() {
                                expect(this.server.lastFetch().params().page).toBe("3");

                                this.server.completeFetchFor(this.collection, [], {page:3}, {page: "3", total: "9999999"});
                                expect(chorus.collections.NotificationSet.prototype.markAllRead).toHaveBeenCalled();
                            });
                        });
                    });
                });
            });

            context("when no more results are available", function() {
                beforeEach(function() {
                    this.collection.pagination.total = "1";
                    this.view.render();
                });

                it("doesn't show the more link", function() {
                    expect(this.view.$(".more_items a")).not.toExist();
                });
            });
        });
    });

    describe("#show", function() {
        beforeEach(function() {
            this.view.render();
            expect(this.view.activities.length).toBe(backboneFixtures.notificationSet().length);
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
