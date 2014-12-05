describe("chorus.views.WorkspaceShowSidebar", function() {
    beforeEach(function() {
        this.modalSpy = stubModals();
        this.model = backboneFixtures.workspace({
            name: "A Cool Workspace",
            id: '123',
            image: {
                icon: "/system/workspaces/images/000/000/005/icon/workspaceimage.jpg",
                original: "/system/workspaces/images/000/000/005/original/workspaceimage.jpg"
            }
        });
    });

    describe("#render", function() {
        beforeEach(function() {
            this.view = new chorus.views.WorkspaceShowSidebar({model: this.model});
            this.view.render();
        });

        it("includes a workspace member list containing the workspace members", function() {
            expect(this.view.workspaceMemberList.collection).toEqual(this.model.members());
        });

        context("the workspace has an image", function() {
            beforeEach(function() {
                spyOn(this.view.model, 'hasImage').andReturn(true);
                this.spyImg = spyOn(this.view.model, 'fetchImageUrl').andReturn("imageUrl1");
                this.view.render();
            });

            it("renders the workspace image", function() {
                expect(this.view.$("img.workspace_image").attr("src")).toContain("imageUrl1");
            });

            it("renders the sidebar when image is changed", function() {
                this.spyImg.andReturn("imageUrl2");
                this.view.model.trigger("image:change");
                expect(this.view.$("img.workspace_image").attr("src")).toContain("imageUrl2");
            });

            context("and the image is loaded", function() {
                beforeEach(function() {
                    spyOn(this.view, 'recalculateScrolling').andCallThrough();
                    this.view.render();
                    this.view.recalculateScrolling.reset();
                    this.view.$('.workspace_image').trigger('load');
                });

                it("calls recalculateScrolling", function() {
                    expect(this.view.recalculateScrolling).toHaveBeenCalled();
                });
            });
        });

        context("the workspace does not have an image", function() {
            beforeEach(function() {
                spyOn(this.view.model, 'hasImage').andReturn(false);
                spyOn(this.view.model, 'fetchImageUrl').andReturn("/party.gif");
                this.view.render();
            });

            it("does not render the workspace image", function() {
                expect(this.view.$("img.workspace_image")).not.toExist();
            });
        });

        it("should have a members list subview", function() {
            expect(this.view.$(".workspace_member_list")[0]).toBe(this.view.workspaceMemberList.el);
        });
    });

    describe("#post_render", function() {
        it("unhides the .after_image area after the .workspace_image loads", function() {
            this.view = new chorus.views.WorkspaceShowSidebar({model: this.model});
            spyOn($.fn, 'removeClass');
            $('#jasmine_content').append(this.view.el);
            this.view.render();
            expect($.fn.removeClass).not.toHaveBeenCalledWith('hidden');
            $(".workspace_image").trigger('load');
            expect($.fn.removeClass).toHaveBeenCalledWith('hidden');
            expect($.fn.removeClass).toHaveBeenCalledOnSelector('.after_image');
        });
    });
});
