describe("chorus.dialogs.WorkspaceMembersMore", function() {
    var workspace, dialog;
    beforeEach(function() {
        workspace = backboneFixtures.workspace();
        dialog = new chorus.dialogs.WorkspaceMembersMore({ pageModel: workspace });
        this.choice = "lastName";
    });

    it("does not re-render when the model changes", function() {
        expect(dialog.persistent).toBeTruthy();
    });

    describe("render", function() {
        beforeEach(function() {
            dialog.render();
        });

        context("when the member list has not yet been fetched", function() {
            it("shows a loading spinner", function() {
                expect(dialog.$('.dialog_content').isLoading()).toBe(true);
            });
        });

        context("when the member list is already fetched", function() {
            beforeEach(function() {
                var self = this;

                this.members = new chorus.collections.UserSet();
                _.times(25, function() {
                    self.members.add(backboneFixtures.user());
                });

                this.sortedMembers = _.sortBy(this.members.models, function(member) {
                    return member.get(self.choice);
                });

                this.server.completeFetchAllFor(dialog.collection, this.members.models);
            });

            it("does not show a loading spinner", function() {
                expect(dialog.$('.dialog_content').isLoading()).toBe(false);
            });

            it("includes an image for each member", function() {
                var images = dialog.$(".collection_list img");
                expect(images.length).toBe(this.sortedMembers.length);
                expect(images.eq(0).attr("src")).toBe(this.sortedMembers[0].fetchImageUrl({ size: 'icon' }));
                expect(images.eq(1).attr("src")).toBe(this.sortedMembers[1].fetchImageUrl({ size: 'icon' }));
            });

            it("includes a name for each member", function() {
                var names = dialog.$('.name');
                expect(names.length).toBe(this.sortedMembers.length);
                expect(names.eq(0).text().trim()).toBe(this.sortedMembers[0].displayName());
                expect(names.eq(23).text().trim()).toBe(this.sortedMembers[23].displayName());
            });

            it("shows the member count", function() {
                expect(dialog.$('.member_count').text().trim()).toMatchTranslation('workspace.members_count', {count: this.sortedMembers.length});
            });

            it("has a close window button that cancels the dialog", function() {
                expect(dialog.$("button.cancel").length).toBe(1);
            });

            describe("sorting", function() {
                it("has a sort by menu", function() {
                    expect(dialog.$(".sort_menu .menus").length).toBe(1);
                });

                it("sorts", function() {
                    dialog.collection.models[20].set({firstName : "AAAAA"});
                    expect(dialog.$('.name').eq(0).text()).not.toContain("AAAAA");
                    dialog.$(".menu li[data-type=firstName] a").click();
                    expect(dialog.$('.name').eq(0).text()).toContain("AAAAA");
                });
            });
        });
    });
});
