describe("chorus.views.DatasetShowContentHeader", function() {
    beforeEach(function() {
        this.model = backboneFixtures.dataset({
            tags: [
                {name: "alpha"}
            ],
            associatedWorkspaces: [backboneFixtures.workspaceJson(), backboneFixtures.workspaceJson(), backboneFixtures.workspaceJson()],
            tableauWorkbooks: [backboneFixtures.tableauWorkbook().attributes, backboneFixtures.tableauWorkbook().attributes, backboneFixtures.tableauWorkbook().attributes]
        });
        this.model.loaded = false;
        delete this.model.statusCode;
        this.model.fetch();
        this.view = new chorus.views.DatasetShowContentHeader({
            model: this.model,
            workspaceId: 123
        });
        this.qtipSpy = stubQtip();

        this.view.render();
    });

    describe('when the dataset is not loaded', function() {
        it('does not render', function() {
            expect(this.view.$('img.icon')).not.toExist();
        });
    });

    describe('when the dataset fetch completes', function() {
        beforeEach(function(){
            this.server.completeFetchFor(this.model);
        });

        it('renders the header', function() {
            expect(this.view.$('img.icon')).toExist();
        });

        it("renders the list of tags", function() {
            expect(this.view.$('.text-tags')).toContainText("alpha");
        });

        it("has a workspace id for the tagbox", function() {
            expect(this.view.tagBox.options.workspaceIdForTagLink).toBe(123);
        });

        describe("tableau publishing details", function() {
            it("is in the custom header", function() {
                expect(this.view.$('.published_to')).toExist();
            });

            it("qtip-ifies the other_menu", function() {
                this.view.$('.published_to .open_other_menu').click();
                expect(this.qtipSpy).toHaveVisibleQtip();
                expect(this.qtipSpy.find('li').length).toBe(2);
            });

            context("when the dataset has not been published to tableau", function() {
                beforeEach(function() {
                    delete this.view.model._tableauWorkbooks;
                    this.view.model.unset("tableauWorkbooks");
                });

                it("renders successfully, without the tableau workbook section", function() {
                    this.view.render();
                    expect(this.view.$('.published_to')).not.toExist();
                });
            });
        });

        describe("workspace usage", function() {
            it("is in the custom header", function() {
                expect(this.view.$('.found_in')).toExist();
            });

            it("qtip-ifies the other_menu", function() {
                this.view.$('.found_in .open_other_menu').click();
                expect(this.qtipSpy).toHaveVisibleQtip();
                expect(this.qtipSpy.find('li').length).toBe(2);
            });

            context("when the tabular data is not used in any workspace", function() {
                beforeEach(function() {
                    delete this.view.model._workspaceAssociated;
                    this.view.model.unset("associatedWorkspaces");
                });

                it("renders successfully, without the workspace usage section", function() {
                    this.view.render();
                    expect(this.view.$('.found_in')).not.toExist();
                });
            });
        });
    });
});