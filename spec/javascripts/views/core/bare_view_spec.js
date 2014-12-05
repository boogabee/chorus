describe("chorus.views.Bare", function() {
    describe("#setupScrolling", function() {
        beforeEach(function() {
            this.page = new chorus.pages.Base();
            chorus.page = this.page;
            this.view = new chorus.views.Bare();
            this.view.template = function() {
                return "<div class='foo'><div class='subfoo'/></div>";
            };
            this.view.subviews = { ".subfoo": "subfoo" };
            this.view.subfoo = new chorus.views.Bare();
            this.view.subfoo.templateName = "plain_text";
            this.view.render();

            spyOn($.fn, "jScrollPane").andCallThrough();
            spyOn($.fn, "hide").andCallThrough();
            spyOn($.fn, "bind").andCallThrough();
            spyOn(this.page, "on").andCallThrough();
            spyOn(this.view, "recalculateScrolling").andCallThrough();
        });

        context("with a valid view", function() {
            beforeEach(function() {
                this.view.setupScrolling(".foo");
            });

            it("defers the setup", function() {
                expect(_.delay).toHaveBeenCalled();
            });

            it("calls jScrollPane", function() {
                expect($.fn.jScrollPane).toHaveBeenCalledOnSelector(".foo");
            });

            it("adds the custom_scroll class to the element", function() {
                expect($(this.view.$(".foo"))).toHaveClass("custom_scroll");
            });

            it("hides the scrollbars initially", function() {
                expect($.fn.hide).toHaveBeenCalledOnSelector(".foo .jspVerticalBar");
                expect($.fn.hide).toHaveBeenCalledOnSelector(".foo .jspHorizontalBar");
            });

            it("binds the view to resized events on the page", function() {
                expect(this.page.on).toHaveBeenCalledWith("resized", jasmine.any(Function), jasmine.any(Object));
            });

            it("binds to the mousewheel event on the container", function() {
                expect($.fn.bind).toHaveBeenCalledOnSelector(".foo .jspContainer");
                expect($.fn.bind).toHaveBeenCalledWith("mousewheel", jasmine.any(Function));
            });

            context("when called again", function() {
                beforeEach(function() {
                    this.page.on.reset();
                    $.fn.hide.reset();
                    $.fn.jScrollPane.reset();
                    $.fn.bind.reset();
                    spyOn(this.view.subfoo, "bind").andCallThrough();
                    this.view.setupScrolling(".foo");
                });

                it("calls jScrollPane", function() {
                    expect($.fn.jScrollPane).toHaveBeenCalledOnSelector(".foo");
                });

                it("hides the scrollbars initially", function() {
                    expect($.fn.hide).toHaveBeenCalledOnSelector(".foo .jspVerticalBar");
                    expect($.fn.hide).toHaveBeenCalledOnSelector(".foo .jspHorizontalBar");
                });

                it("does not re-bind the view to resized events on the page", function() {
                    expect(this.page.on).not.toHaveBeenCalledWith("resized", jasmine.any(Function), jasmine.any(Object));
                });

                it("does not re-bind to the mousewheel event on the container", function() {
                    expect($.fn.bind).not.toHaveBeenCalledOnSelector(".foo .jspContainer");
                });
            });

            describe("when a resized event occurs", function() {
                beforeEach(function() {
                    spyOn(this.view.$(".foo").data("jsp"), "reinitialise");
                    this.page.trigger("resized");
                });

                it("recalculates scrolling", function() {
                    expect(this.view.$(".foo").data("jsp").reinitialise).toHaveBeenCalled();
                });
            });

            describe("when a mousewheel event occurs", function() {
                beforeEach(function() {
                    this.event = jQuery.Event("mousewheel");
                    this.view.$(".jspContainer").trigger(this.event);
                });

                it("prevents default", function() {
                    expect(this.event.isDefaultPrevented()).toBeTruthy();
                });
            });

            describe("when a subview is re-rendered", function() {
                beforeEach(function() {
                    this.view.recalculateScrolling.reset();
                    this.view.subfoo.render();
                });

                it("recalculates scrolling", function() {
                    expect(this.view.recalculateScrolling).toHaveBeenCalled();
                });
            });

            describe("when a subview triggers content:changed", function() {
                beforeEach(function() {
                    this.view.recalculateScrolling.reset();
                    chorus.PageEvents.trigger("content:changed");
                });

                it("recalculates scrolling", function() {
                    expect(this.view.recalculateScrolling).toHaveBeenCalled();
                });
            });

            describe("when the element scrolls", function() {
                beforeEach(function() {
                    spyOnEvent(this.view, 'scroll');
                    this.view.$(".foo").trigger("jsp-scroll-y");
                });

                it("triggers the 'scroll' event on itself", function() {
                    expect('scroll').toHaveBeenTriggeredOn(this.view);
                });
            });

            describe("delegateEvents", function() {
                var noEventsClass = chorus.views.Bare.extend({
                    template: function() {
                        return '<div class="hello world"></div>';
                    }
                });
                var noEventsChildClass = noEventsClass.extend({
                    events: {
                        "click .world": 'noEventsChildFunction'
                    },
                    noEventsChildFunction: jasmine.createSpy('noEventsChildFunction')
                });
                var grandparentViewClass = chorus.views.Bare.extend({
                    events: {
                        "click .world": 'grandparentFunction',
                        "click .hello": "badFunction"
                    },
                    template: function() {
                        return '<div class="hello world"></div>';
                    },
                    grandparentFunction: jasmine.createSpy('grandparentFunction'),
                    badFunction: jasmine.createSpy('badFunction')
                });
                var parentViewClass = grandparentViewClass.extend({
                    events: {
                        "click .hello": 'parentFunction'
                    },

                    parentFunction: jasmine.createSpy('parentFunction')
                });
                var childViewClass = parentViewClass.extend({
                    events: {
                        "click div.hello": 'childFunction'
                    },
                    childFunction: jasmine.createSpy('childFunction')
                });

                it("binds all sets of events", function() {
                    this.view = new childViewClass();
                    this.view.render();
                    this.view.$('.hello').click();
                    expect(this.view.childFunction).toHaveBeenCalled();
                    expect(this.view.parentFunction).toHaveBeenCalled();
                    expect(this.view.grandparentFunction).toHaveBeenCalled();
                    expect(this.view.badFunction).not.toHaveBeenCalled();
                });

                it("works if there are no events", function() {
                    this.view = new noEventsClass();
                    this.view.render();
                    expect(this.view.$('.hello')).toExist();
                });

                it("works if the parent has no events", function() {
                    this.view = new noEventsChildClass();
                    this.view.render();
                    this.view.$('.hello').click();
                    expect(this.view.noEventsChildFunction).toHaveBeenCalled();
                });
            });
        });

        context("when called after teardown (due to the defer)", function() {
            beforeEach(function() {
                this.view.teardown();
                spyOn(this.view, "listenTo");
                this.view.setupScrolling(".foo");
            });

            it("does not bind anything to the view", function() {
                expect($.fn.bind).not.toHaveBeenCalled();
                expect(this.view.listenTo).not.toHaveBeenCalled();
            });
        });
    });

    describe("#subscribePageEvent", function() {
        beforeEach(function() {
            this.view = new chorus.views.Bare();
            this.fun = function() {};
        });

        it("listens to events from page events", function() {
            this.view.subscribePageEvent("testevent", this.fun);
            expect(this.view).toHaveSubscription("testevent", this.fun);
        });

        it("won't bind more than once", function() {
            this.callbackSpy = jasmine.createSpy("callback");
            this.view.subscribePageEvent("testevent", this.callbackSpy);
            this.view.subscribePageEvent("testevent", this.callbackSpy);
            this.view.subscribePageEvent("testevent", this.callbackSpy);
            chorus.PageEvents.trigger("testevent");
            expect(this.callbackSpy.calls.count()).toBe(1);
        });
    });

    describe("#teardown", function() {
        beforeEach(function() {
            this.view = new chorus.views.Bare();
            this.view.templateName = "plain_text";
            this.view.context = function() { return { text: "Foo" }; };

            $("#jasmine_content").append($(this.view.render().el));
            expect($(this.view.el).closest("#jasmine_content")).toExist();

            this.model = new chorus.models.Base();
            this.view.requiredResources.add(this.model);
            this.subViewObject = stubView();
            spyOn(this.subViewObject, "teardown");
            this.view.registerSubView(this.subViewObject);

            spyOn(this.view, "unbind");
            expect(this.view.requiredResources.models.length).toBe(1);

            this.view.subscribePageEvent("foo", this.view.render);
            this.view.teardown();
        });

        it("sets torndown to true", function() {
            expect(this.view.torndown).toBeTruthy();
        });

        it("should call cleanup functions", function() {
            expect(this.view.unbind).toHaveBeenCalled();
            expect(_.isEmpty(this.view.requiredResources.models)).toBeTruthy();
        });

        it("should remove itself from the DOM", function() {
            expect($(this.view.el).closest("#jasmine_content")).not.toExist();
        });

        it("should tear down registered subviews", function() {
            expect(this.subViewObject.teardown).toHaveBeenCalled();
        });

        describe("when the teardown function is told to preserve the container", function() {
            beforeEach(function() {
                this.view = new chorus.views.Bare();
                this.view.templateName = "plain_text";
                this.view.context = function() { return { text: "Foo" }; };

                $("#jasmine_content").append($(this.view.render().el));
                expect($(this.view.el).closest("#jasmine_content")).toExist();

                this.view.teardown(true);
            });
            it("keeps itself in the DOM", function() {
                expect($(this.view.el).closest("#jasmine_content")).toExist();
            });
            it("contains nothing", function() {
                expect($(this.view.el).html()).toBe("");
            });
        });
    });

    describe("#registerSubViews", function() {
        beforeEach(function() {
            this.view = new chorus.views.Bare();
            this.subViewObject = stubView();
            this.view.registerSubView(this.subViewObject);
        });

        it("adds the view to the subViewObjects array", function() {
            expect(this.view.getSubViews()[0]).toBe(this.subViewObject);
        });

        it("it doesn't add the same view twice", function() {
            this.view.registerSubView(this.subViewObject);
            this.view.registerSubView(this.subViewObject);
            expect(this.view.getSubViews().length).toBe(1);
        });
    });

    describe("#onceLoaded", function() {
        beforeEach(function() {
            this.view = new chorus.views.Base();
            this.model = new chorus.models.Base();
            this.callback = jasmine.createSpy("callback");
        });

        describe("when the model has already been loaded", function() {
            it("calls the callback", function() {
                this.model.loaded = true;

                expect(this.callback).not.toHaveBeenCalled();
                this.view.onceLoaded(this.model, this.callback);
                expect(this.callback).toHaveBeenCalled();
            });
        });

        describe("when the model has not been loaded yet", function() {
            it("calls the callback on the loaded event once", function() {
                this.model.loaded = false;

                this.view.onceLoaded(this.model, this.callback);
                expect(this.callback).not.toHaveBeenCalled();
                this.model.trigger('loaded');
                expect(this.callback).toHaveBeenCalled();
                this.model.trigger('loaded');
                expect(this.callback.calls.count()).toBe(1);
            });
        });
    });

    describe("#menu", function() {
        beforeEach(function() {
            chorus._navigated();
            this.view = new chorus.views.Bare();
            var viewElement = $('<div><div class="menu_goes_here"></div></div>');
            this.element = viewElement.find(".menu_goes_here");
            this.view.setElement(viewElement);
            this.qtipElement = stubQtip();
            this.eventSpy = jasmine.createSpy();

            this.view.menu('.menu_goes_here', {
                content: "menu content<a class='test_link'></a>",
                classes: "myClass",
                style: {foo: 'bar'},
                mimic: "left center",
                position: {
                    my: "left center",
                    at: "right center"
                },
                contentEvents: {
                    '.test_link': this.eventSpy
                }
            });
            this.qtipArgs = $.fn.qtip.lastCall().args[0];
        });

        it("calls qtip on the given element", function() {
            expect($.fn.qtip.lastCall().object.get(0)).toEqual(this.element.get(0));
        });

        it("passes down the given content", function() {
            expect(this.qtipArgs.content).toEqual("menu content<a class='test_link'></a>");
        });

        it("sets up the events on the contents", function() {
            this.element.click();
            this.qtipElement.find('.test_link').click();
            expect(this.eventSpy).toHaveBeenCalledWith(jasmine.any(jQuery.Event), this.element.data('qtip'));
        });

        context("event handling", function() {
            beforeEach(function() {
                this.element.click();
            });

            it("closes the qtip", function() {
                expect(this.qtipElement).toHaveVisibleQtip();
                this.qtipElement.find('.test_link').click();
                expect(this.qtipElement).not.toHaveVisibleQtip();
            });
        });

        it("sets up our menu styling", function() {
            expect(this.qtipArgs.show.event).toEqual('click');
            expect(this.qtipArgs.hide).toEqual('unfocus');
            expect(this.qtipArgs.position.my).toEqual("left center");
            expect(this.qtipArgs.position.at).toEqual("right center");
            expect(this.qtipArgs.style).toEqual({
                classes: "myClass tooltip-white",
                foo: "bar",
                tip: {
                    mimic: "left center",
                    width: 20,
                    height: 15
                }
            });
        });

        context("after navigating away", function() {
            beforeEach(function() {
                spyOn($.fn, 'remove');
                chorus._navigated();
            });

            it("calls $.fn.remove on the menu element", function() {
                expect($.fn.remove.lastCall().object.get(0)).toEqual(this.element.get(0));
            });
        });
    });

});
