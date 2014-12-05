describe("chorus.views.TagListSidebar", function() {
    beforeEach(function() {
        this.tags = new chorus.collections.TagSet([
            {name: "Hello"}
        ]);
        this.view = new chorus.views.TagListSidebar();
        this.selectedTag = this.tags.first();
    });

    it("displays the tag name selected on the page", function() {
        chorus.PageEvents.trigger('tag:selected', this.selectedTag);
        expect(this.view.$el).toContainText('Hello');
    });

    it("is empty if no tag is select", function() {
        chorus.PageEvents.trigger('tag:selected', this.selectedTag);
        chorus.PageEvents.trigger('tag:deselected');
        expect(this.view.$el.html().trim()).toEqual('');
    });

    describe("delete tag link", function() {
        context("user is admin", function() {
            beforeEach(function() {
                setLoggedInUser({admin: true}, chorus);
                chorus.PageEvents.trigger('tag:selected', this.selectedTag);
                this.deleteLink = this.view.$(".actions a.delete_tag_link");
            });

            it("displays the delete tag link", function() {
                expect(this.deleteLink).toExist();
                expect(this.deleteLink).toContainTranslation('tag_list.delete.button');
            });

            context("clicking the tag", function() {
                beforeEach(function() {
                    this.launchModalSpy = jasmine.createSpy("launchModal");
                    this.fakeAlert = { launchModal: this.launchModalSpy };
                    spyOn(chorus.alerts, "TagDelete").andCallFake(_.bind(function(options) {
                        expect(options.model).toBe(this.view.tag);
                        return this.fakeAlert;
                    }, this));
                });

                it("opens the rename tag dialog", function() {
                    this.deleteLink.click();
                    expect(chorus.alerts.TagDelete).toHaveBeenCalled();
                    expect(this.launchModalSpy).toHaveBeenCalled();
                });
            });
        });

        context("user is not admin", function() {
            beforeEach(function() {
                setLoggedInUser({admin: false}, chorus);
                chorus.PageEvents.trigger('tag:selected', this.selectedTag);
                this.deleteLink = this.view.$el.find(".actions a.delete_tag_link");
            });

            it("does not display the delete tag link", function() {
                expect(this.deleteLink).not.toExist();
            });
        });
    });

    describe("rename tag link", function() {
        beforeEach(function() {
            setLoggedInUser({admin: false}, chorus);
            chorus.PageEvents.trigger('tag:selected', this.selectedTag);
            this.renameLink = this.view.$el.find(".actions a.rename_tag_link");
        });

        it("does not display the rename tag link", function() {
            expect(this.renameLink).toExist();
            expect(this.renameLink).toContainTranslation("tag_list.rename.button");
        });

        context("clicking rename tag", function() {
            beforeEach(function() {
                this.launchModalSpy = jasmine.createSpy("launchModal");
                this.fakeDialog = { launchModal: this.launchModalSpy };
                spyOn(chorus.dialogs, "RenameTag").andCallFake(_.bind(function(options) {
                    expect(options.model).toBe(this.view.tag);
                    return this.fakeDialog;
                }, this));
            });

            it("opens the rename tag dialog", function() {
                this.renameLink.click();
                expect(chorus.dialogs.RenameTag).toHaveBeenCalled();
                expect(this.launchModalSpy).toHaveBeenCalled();
            });
        });
    });
});