jasmine.sharedExamples.PageItemList = function () {
    describe("a selectable list", function () {
        beforeEach(function () {
            spyOn(chorus.PageEvents, "trigger").andCallThrough();
            spyOn(this.view.selectedModels, "reset").andCallThrough();
        });

        function safeClick(target) {
            var checked = $(target).prop('checked');
            $(target).click();
            $(target).prop('checked', !checked);
        }

        function anItemIsCheckable(otherAssertions) {
            describe("And I check an item's checkbox", function () {
                var $item;

                beforeEach(function () {
                    $item = this.view.$('.item_wrapper').last();
                    var checkbox = $item.find('input[type=checkbox]');
                    safeClick(checkbox);
                });

                it("Then the item's name appears in the list of selected items", function () {
                    var event = this.view.eventName + ":checked";
                    var collection = jasmine.any(chorus.collections.Base);

                    expect(chorus.PageEvents.trigger).toHaveBeenCalledWith(event, collection);
                });

                it("Then the item is both checked and highlighted. ", function () {
                    expect($item).toHaveClass('checked');
                });

                otherAssertions && otherAssertions();
            });
        }

        function nothingIsSelected() {
            it("Then all items in the list are neither checked nor highlighted.", function () {
                var $items = this.view.$('.item_wrapper');

                $items.each(function (i, item) {
                    var $item = $(item);
                    expect($item).not.toHaveClass('checked');
                    var checkbox = $item.find('input[type=checkbox]');
                    expect(checkbox).not.toBeChecked();
                });
            });
        }

        function typedEventNameIsSent() {
            it("triggers the '{{eventName}}:checked' event with the collection of currently-checked items", function() {
                var entityCheckedEvent = this.view.options.entityType + ":checked";
                expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("checked", jasmine.any(chorus.collections[this.collection.constructorName]));
                expect(chorus.PageEvents.trigger).toHaveBeenCalledWith(entityCheckedEvent, jasmine.any(chorus.collections[this.collection.constructorName]));
            });
        }

        function lastCheckEvent(entityCheckedEvent) {
            var anyEventAboutChecking = function (call) {
                return call.args[0] === "checked" || call.args[0] === entityCheckedEvent;
            };

            var allTriggers = chorus.PageEvents.trigger.calls.all();
            return _(allTriggers).chain().filter(anyEventAboutChecking).last().value();
        }

        function lastSelectEvent(entitySelectEvent) {
            var anyEventAboutChecking = function (call) {
                return call.args[0] === entitySelectEvent;
            };

            var allTriggers = chorus.PageEvents.trigger.calls.all();
            return _(allTriggers).chain().filter(anyEventAboutChecking).last().value();
        }

        function onlyFirstModelIsSentInEvents() {
            typedEventNameIsSent();

            it("sends the clicked model's ID in a page event", function () {
                var lastCall        = lastCheckEvent(this.view.options.entityType + ":checked");
                var collection      = lastCall.args[1];
                var broadcastIDs    = collection.pluck("id");
                var clickedIDs      = [this.collection.first().get('id')];

                expect(broadcastIDs).toEqual(clickedIDs);
            });
        }

        function allModelsAreSentInEvents() {
            typedEventNameIsSent();

            it("sends all models' IDs in a page event", function () {
                var lastCall = lastCheckEvent(this.view.options.entityType + ":checked");
                var broadcastIDs = lastCall.args[1].pluck("id");
                var clickedIDs = this.collection.pluck('id');

                expect(broadcastIDs).toEqual(clickedIDs);
            });
        }

        function noModelsAreSentInEvents() {
            typedEventNameIsSent();

            it("sends all models' IDs in a page event", function () {
                var lastCall = lastCheckEvent(this.view.options.entityType + ":checked");
                var broadcastIDs = lastCall.args[1].pluck("id");
                var clickedIDs = [];

                expect(broadcastIDs).toEqual(clickedIDs);
            });
        }

        function searchDeselectsAllItems() {
            describe("when eventName:search is triggered", function() {
                beforeEach(function() {
                    chorus.PageEvents.trigger(this.view.options.entityType + ":search");
                });

                nothingIsSelected();
                noModelsAreSentInEvents();
            });
        }

        function paginatesCleanly() {
            describe("loading the next page of results", function() {
                beforeEach(function() {
                    this.view.collection.fetchPage(2);
                    this.server.completeFetchFor(this.view.collection, this.collection.models, {page: 2}, {page: 2});
                });

                it("selects nothing", function() {
                    expect(this.view.$('.selected').length).toBe(0);
                });
            });
        }

        it("renders each item in the collection", function() {
            expect(this.view.$("li").length).toBe(this.view.collection.length);
        });

        describe('when an item is changed', function(){
            it("does not re-render the entire list", function() {
                spyOn(this.view, 'preRender');
                this.collection.at(0).trigger('change');
                expect(this.view.preRender).not.toHaveBeenCalled();
            });

            context("when the tags on an item are changed", function() {
                it("re renders the item's view", function() {
                    spyOn(this.view.entityViewType.prototype, 'render');
                    this.view.render();
                    this.view.liViews[0].itemView.render.reset();
                    this.collection.at(0).trigger('change:tags');
                    expect(this.view.liViews[0].itemView.render).toHaveBeenCalled();
                    expect(this.view.entityViewType.prototype.render.calls.count()).toEqual(1);
                });
            });
        });

        context("When no items are selected", function () {
            nothingIsSelected();
            anItemIsCheckable();
            paginatesCleanly();
            searchDeselectsAllItems();

            describe("And I double-click a checkbox", function () {
                beforeEach(function () {
                    var $items = this.view.$('.item_wrapper');
                    var checkbox = $items.first().find('input[type=checkbox]');

                    safeClick(checkbox);
                    safeClick(checkbox);
                });

                nothingIsSelected();
                noModelsAreSentInEvents();
            });

            describe("And I click the body of an item", function () {
                beforeEach(function () {
                    this.$firstItem = this.view.$('.item_wrapper').first();
                    safeClick(this.$firstItem);
                });

                it("selects the item", function() {
                    expect(this.$firstItem).toHaveClass("checked");
                    expect(chorus.PageEvents.trigger).toHaveBeenCalledWith(this.view.options.entityType + ":selected", this.collection.at(0));
                    expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("selected", this.collection.at(0));
                    expect(chorus.PageEvents.trigger).toHaveBeenCalledWith('checked', jasmine.any(chorus.collections[this.collection.constructorName]));
                });

                it("Then the top level checkbox is semi-filled", function () {
                    expect(chorus.PageEvents.trigger).toHaveBeenCalledWith('unselectAny');
                });

                onlyFirstModelIsSentInEvents();

                describe("And then check another item", function () {
                    beforeEach(function () {
                        this.$lastItem = this.view.$('.item_wrapper').last();
                        safeClick(this.$lastItem.find('input'));
                    });

                    it("Both items should be checked & highlighted", function () {
                        var $items = [this.$firstItem, this.$lastItem];

                        _.each($items, function ($item) {
                            expect($item).toHaveClass('checked');
                            var checkbox = $item.find('input[type=checkbox]');
                            expect(checkbox).toBeChecked();
                        });
                    });

                    describe("And then uncheck the first item", function () {
                        beforeEach(function () {
                            chorus.PageEvents.trigger.reset();
                            safeClick(this.$firstItem.find('input'));
                        });

                        it("Shows actions for the second item", function () {
                            expect(chorus.PageEvents.trigger).toHaveBeenCalled();
                            var selectEvent = lastSelectEvent(this.view.eventName + ':selected');
                            expect(selectEvent).toBeDefined();
                            var selectedModelID = selectEvent.args[1].id;
                            var lastModelID = this.collection.last().id;

                            expect(selectedModelID).toBe(lastModelID);
                        });

                    });

                });

                describe("And then click the body of another item", function () {
                    beforeEach(function () {
                        this.$lastItem = this.view.$('.item_wrapper').last();
                        safeClick(this.$lastItem);
                    });

                    it("Only the second item is checked & highlighted", function () {
                        expect(this.$lastItem).toHaveClass('checked');
                        var checkbox = this.$lastItem.find('input[type=checkbox]');
                        expect(checkbox).toBeChecked();
                    });
                });
            });

            describe("And I click the top level checkbox", function () {
                beforeEach(function () {
                    chorus.PageEvents.trigger('selectAll');
                });

                it("Then all items in the list are selected", function () {
                    var $items = this.view.$('.item_wrapper');

                    $items.each(function (i, item) {
                        expect($(item)).toHaveClass('checked');

                        var checkbox = $(item).find('input[type=checkbox]');
                        expect(checkbox).toBeChecked();
                    });
                });

                allModelsAreSentInEvents();
            });

            describe("And I check an item's checkbox", function () {
                beforeEach(function () {
                    chorus.PageEvents.trigger.reset();

                    var $items = this.view.$('.item_wrapper');
                    var checkbox = $items.first().find('input[type=checkbox]');
                    safeClick(checkbox);
                });

                onlyFirstModelIsSentInEvents();
            });

            describe('shift+click', function() {
                beforeEach(function() {
                    expect(this.view.$("input[type=checkbox]:checked").length).toBe(0);
                    expect(this.collection.models.length).toBeGreaterThan(2);

                    chorus.PageEvents.on("checked", function(collection) {
                        this.checkedModels = collection.models;
                    }, this);
                });

                function shiftClick(target) {
                    var event = jQuery.Event("click");
                    event.shiftKey = true;
                    target.trigger(event);
                }

                describe("holding shift and clicking selects the item in between", function() {
                    it("clicking top to bottom", function() {
                        this.view.$("li:first input[type=checkbox]").click();
                        shiftClick(this.view.$("li:eq(2) input[type=checkbox]"));
                        expect(this.checkedModels.length).toBe(3);
                        expect(this.checkedModels).toContain(this.collection.at(0));
                        expect(this.checkedModels).toContain(this.collection.at(1));
                        expect(this.checkedModels).toContain(this.collection.at(2));
                    });

                    it("clicking bottom to top", function() {
                        this.view.$("li:eq(2) input[type=checkbox]").click();
                        shiftClick(this.view.$("li:first input[type=checkbox]"));
                        expect(this.checkedModels.length).toBe(3);
                        expect(this.checkedModels).toContain(this.collection.at(0));
                        expect(this.checkedModels).toContain(this.collection.at(1));
                        expect(this.checkedModels).toContain(this.collection.at(2));
                    });
                });

                it("clicking without holding shift only selects the clicked item", function() {
                    this.view.$("li:first input[type=checkbox]").click();
                    this.view.$("li:eq(2) input[type=checkbox]").click();
                    expect(this.checkedModels.length).toBe(2);
                    expect(this.checkedModels).toContain(this.collection.at(0));
                    expect(this.checkedModels).not.toContain(this.collection.at(1));
                    expect(this.checkedModels).toContain(this.collection.at(2));
                });

                it("unchecking resets shift+click selection", function() {
                    this.view.$("li:first input[type=checkbox]").click().click();
                    shiftClick(this.view.$("li:last input[type=checkbox]"));
                    expect(this.checkedModels.length).toBe(1);
                    expect(this.checkedModels).toContain(this.collection.at(this.collection.length-1));
                });
            });
        });

        context("When a populated proper subset of items are selected", function () {
            var $items, $initiallySelectedItems;

            beforeEach(function () {
                $items = this.view.$('.item_wrapper');

                var checkbox = $items.first().find('input[type=checkbox]');

                safeClick(checkbox);
                $initiallySelectedItems = this.view.$('.item_wrapper.checked');

                expect($initiallySelectedItems.length).toBeGreaterThan(0);
                expect($initiallySelectedItems.length).toBeLessThan($items.length);
            });

            paginatesCleanly();
            searchDeselectsAllItems();

            it("Then the top level checkbox is semi-filled", function () {
                expect(chorus.PageEvents.trigger).toHaveBeenCalledWith('unselectAny');
            });

            describe("And I uncheck all the selected items", function () {
                beforeEach(function () {
                    var $selectedItems = this.view.$('.item_wrapper.checked');

                    $selectedItems.each(function (i, item) {
                        var checkbox = $(item).find('input[type=checkbox]');
                        safeClick(checkbox);
                    });
                });

                it("then the top level checkbox is empty", function () {
                    expect(chorus.PageEvents.trigger).toHaveBeenCalledWith('noneSelected');
                });
            });

            describe("And I click the top-level checkbox", function () {
                beforeEach(function () {
                    chorus.PageEvents.trigger("selectNone");
                });

                nothingIsSelected();
                noModelsAreSentInEvents();
            });

            anItemIsCheckable(function () {
                it("And the previously selected items remain highlighted and checked.", function () {
                    $initiallySelectedItems.each(function (i, item) {
                        expect($(item)).toHaveClass('checked');

                        var checkbox = $(item).find('input[type=checkbox]');
                        expect(checkbox).toBeChecked();
                    });
                });
            });

            describe("And the collection completes a fetch", function () {
                beforeEach(function () {
                    this.view.collection.fetch();
                    this.server.completeFetchFor(this.view.collection, this.view.collection.models);
                });

                it("retains checked items", function() {
                    var $currentlyCheckedBoxes = this.view.$("input[type=checkbox]:checked");

                    expect($currentlyCheckedBoxes.length).toBe($initiallySelectedItems.length);
                    expect($initiallySelectedItems.find("input")).toBeChecked();
                });
            });

            describe("And an item changes", function () {
                beforeEach(function () {
                    this.view.collection.first().trigger('change');
                });

                it("retains checked items", function() {
                    var $currentlyCheckedBoxes = this.view.$("input[type=checkbox]:checked");

                    expect($currentlyCheckedBoxes.length).toBe($initiallySelectedItems.length);
                    expect($initiallySelectedItems.find("input")).toBeChecked();
                });
            });

            describe("And clear_selection is triggered for that item", function() {
                it("un-checks the entry", function() {
                    var firstCheckbox = this.view.$("li input[type=checkbox]").eq(0);
                    var firstModel = this.view.selectedModels.first();

                    expect(firstCheckbox).toBeChecked();
                    chorus.PageEvents.trigger("clear_selection", firstModel);
                    expect(firstCheckbox).not.toBeChecked();
                });
            });
        });

        context("When all items are selected", function () {
            beforeEach(function () {
                chorus.PageEvents.trigger.reset();

                var $allItems = this.view.$('.item_wrapper');

                $allItems.each(function (i, item) {
                    var checkbox = $(item).find('input[type=checkbox]');
                    safeClick(checkbox);
                });
            });

            paginatesCleanly();
            searchDeselectsAllItems();

            it("Then the top level checkbox is checked", function () {
                expect(chorus.PageEvents.trigger).toHaveBeenCalledWith('allSelected');
            });

            describe("And I click the top-level checkbox", function () {
                beforeEach(function () {
                    chorus.PageEvents.trigger("selectNone");
                });

                nothingIsSelected();
                noModelsAreSentInEvents();
            });
        });

        it("doesn't check models with the same id but different entity types", function() {
            var decoyModel = this.view.collection.at(0).clone();
            decoyModel.set({entityType: "notReal"});

            this.view.selectedModels.reset(this.collection.models.slice(1));
            this.view.selectedModels.add([decoyModel]);
            chorus.PageEvents.trigger("checked", this.view.selectedModels);

            expect(this.view.$("input[type=checkbox]").eq(0)).not.toBeChecked();
            expect(this.view.$("input[type=checkbox]").eq(1)).toBeChecked();
        });
    });
};