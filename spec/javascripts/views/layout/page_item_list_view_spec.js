describe("chorus.views.PageItemList", function() {
    beforeEach(function() {
        this.collection = new chorus.collections.UserSet([
            backboneFixtures.user({id: 123}),
            backboneFixtures.user({id: 456}),
            backboneFixtures.user({id: 789})
        ], {schemaId: "3"});

        this.view = new chorus.views.PageItemList({
            entityType: 'user',
            entityViewType: chorus.views.UserItem,
            collection: this.collection,
            listItemOptions: {itemOption: 123}
        });

        this.view.render();
    });

    itBehavesLike.PageItemList();

    describe("creating the item views", function() {
        it("passes through the list item options", function() {
            expect(this.view.liViews[0].itemView.options.itemOption).toBe(123);
        });
    });

    describe("#setup", function() {
        it("uses selectedModels if passed one", function() {
            this.checkedModels = new chorus.collections.Base();
            this.view = new chorus.views.PageItemList({
                entityType: 'user',
                entityViewType: chorus.views.UserItem,
                collection: this.collection,
                selectedModels: this.checkedModels
            });
            expect(this.checkedModels).toBe(this.checkedModels);
        });

        describe("event names", function() {
            it("uses the entityType as the event name by default", function() {
                var eventSpy = jasmine.createSpy("selectedSpy");
                chorus.PageEvents.on("user:selected", eventSpy);
                this.view.render();
                expect(this.view.$('li:eq(1)')).toExist();
                this.view.$('li:eq(1)').click();
                expect(eventSpy).toHaveBeenCalled();
            });

            it("uses eventName if passed one", function() {
                var eventSpy = jasmine.createSpy();
                chorus.PageEvents.on("alternate_event_name:selected", eventSpy);
                this.view = new chorus.views.PageItemList({
                    eventName: 'alternate_event_name',
                    entityType: 'user',
                    entityViewType: chorus.views.UserItem,
                    collection: this.collection
                });
                this.view.render();
                this.view.$('li:first').click();
                expect(eventSpy).toHaveBeenCalled();
            });
        });
    });
});
