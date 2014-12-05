describe('chorus.views.AlpineWorkfileSidebar', function(){
    beforeEach(function(){
        this.workfile = backboneFixtures.workfile.alpine();
        this.view = new chorus.views.AlpineWorkfileSidebar({model: this.workfile, showVersions: true});
        this.view.render();
    });

    it('does not render the versions', function(){
        expect(this.view.$(".version_list")).not.toExist();
    });

    it('does not render the download link', function(){
        expect(this.view.$('.actions a.download')).not.toExist();
    });

    it('does not render the update time', function(){
        expect(this.view.$('.info .updated')).not.toExist();
    });

    describe("run now", function () {
        context("when the user has workspace permissions", function () {
            beforeEach(function () {
                spyOn(this.workfile.workspace(), 'canUpdate').andReturn(true);
                this.view.render();
            });

            it('shows the run now link', function () {
                expect(this.view.$('a.run_now')).toContainTranslation('work_flows.actions.run_now');
                expect(this.view.$('span.run_now')).not.toExist();
            });

            it('shows a disabled stop link', function () {
                expect(this.view.$('span.stop')).toContainTranslation('work_flows.actions.stop');
                expect(this.view.$('span.stop')).toHaveClass('disabled');
                expect(this.view.$('a.stop')).not.toExist();
            });

            context('clicking run now', function () {
                beforeEach(function () {
                    spyOn(this.view.model, 'run').andCallThrough();
                    this.view.$('a.run_now').click();
                    this.server.lastCreate().succeed(this.view.model.set({status: 'running'}));
                });

                it('disables the run now link', function () {
                    expect(this.view.$('span.run_now')).toHaveClass('disabled');
                    expect(this.view.$('a.run_now')).not.toExist();
                });

                it("enables the 'stop' link", function () {
                    expect(this.view.$('a.stop')).toContainTranslation('work_flows.actions.stop');
                    expect(this.view.$('span.stop')).not.toExist();
                });

                it('runs the workfile', function () {
                    expect(this.view.model.run).toHaveBeenCalled();
                });

                context('clicking stop now', function () {
                    beforeEach(function () {
                        spyOn(this.view.model, 'stop').andCallThrough();
                        this.view.$('a.stop').click();
                        this.server.lastCreate().succeed(this.view.model.set({status: 'idle'}));
                    });

                    it('stops the workfile', function () {
                        expect(this.view.model.stop).toHaveBeenCalled();
                    });

                    it('reenables the run now link', function () {
                        expect(this.view.$('a.run_now')).toExist();
                        expect(this.view.$('span.run_now')).not.toExist();
                    });

                    it("disables the 'stop' link", function () {
                        expect(this.view.$('a.stop')).not.toExist();
                        expect(this.view.$('span.stop')).toHaveClass('disabled');
                    });
                });

            });
        });

        context("when the user does not have workspace permissions", function () {
            beforeEach(function () {
                spyOn(this.workfile.workspace(), 'canUpdate').andReturn(false);
                this.view.render();
            });

            it("does not show run/stop links", function () {
                expect(this.view.$('.run_now')).not.toExist();
                expect(this.view.$('.stop_now')).not.toExist();
            });
        });

        context("when the workspace is archived", function () {
            beforeEach(function(){
                spyOn(this.workfile.workspace(), 'isActive').andReturn(false);
                this.view.render();
            });

            it("does not show run/stop links", function () {
                expect(this.view.$('.run_now')).not.toExist();
                expect(this.view.$('.stop_now')).not.toExist();
            });
        });
    });
});
