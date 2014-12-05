describe("chorus.views.WorkfileContentDetails", function() {
    beforeEach(function() {
        this.model = backboneFixtures.workfile.sql();
        this.workspace = this.model.workspace();
        this.workspace.set({ archivedAt: null });
    });

    describe(".buildFor", function() {
        context("when the given workfile is an image", function() {
            beforeEach(function() {
                this.model = backboneFixtures.workfile.image();
            });

            it("instantiates an ImageWorkfileContentDetails view with the given workfile", function() {
                var contentDetails = chorus.views.WorkfileContentDetails.buildFor(this.model);
                expect(contentDetails).toBeA(chorus.views.ImageWorkfileContentDetails);
            });
        });

        context("when the given workfile is a SQL file", function() {
            beforeEach(function() {
                this.model = backboneFixtures.workfile.sql();
            });

            context("when its workspace is active (not archived)", function() {
                context("when the workspace is updateable", function() {
                    beforeEach(function() {
                        spyOn(this.model.workspace(), 'canUpdate').andReturn(true);
                        spyOn(this.model.workspace(), 'isActive').andReturn(true);
                    });

                    it("instantiates a SqlWorkfileContentDetails view", function() {
                        var contentDetails = chorus.views.WorkfileContentDetails.buildFor(this.model);
                        expect(contentDetails).toBeA(chorus.views.SqlWorkfileContentDetails);
                    });
                });
                context("when the workspace is not updateable", function() {
                    beforeEach(function() {
                        spyOn(this.model.workspace(), 'canUpdate').andReturn(false);
                    });

                    it("instantiates a ReadOnlyWorkfileContentDetails", function() {
                        var contentDetails = chorus.views.WorkfileContentDetails.buildFor(this.model);
                        expect(contentDetails).toBeA(chorus.views.SqlWorkfileContentDetails);
                    });
                });
            });

            context("when its workspace is archived", function() {
                it("instantiates a ArchivedWorkfileContentDetails view", function() {
                    spyOn(this.model.workspace(), 'isActive').andReturn(false);
                    var contentDetails = chorus.views.WorkfileContentDetails.buildFor(this.model);
                    expect(contentDetails).toBeA(chorus.views.ArchivedWorkfileContentDetails);
                });
            });
        });

        context("when the given workfile is a partial file", function() {
            beforeEach(function() {
                this.model = backboneFixtures.workfile.sql({versionInfo: {partialFile: true}});
            });

            it("instantiates a PartialWorkfileContentDetails", function() {
                var contentDetails = chorus.views.WorkfileContentDetails.buildFor(this.model);
                expect(contentDetails).toBeA(chorus.views.PartialWorkfileContentDetails);
            });
        });

        context("when the given workfile is an xml file", function() {
            beforeEach(function() {
                this.model = backboneFixtures.workfile.sql();
                this.model.set('fileType', 'xml');
            });

            it("instantiates a ReadOnlyWorkfileContentDetails", function() {
                var contentDetails = chorus.views.WorkfileContentDetails.buildFor(this.model);
                expect(contentDetails).toBeA(chorus.views.ReadOnlyWorkfileContentDetails);
            });
        });

        context("when the given workfile is an Alpine file", function() {
            beforeEach(function() {
                this.model = backboneFixtures.workfile.binary({ fileType: "alpine" });
                spyOn(chorus.views, "AlpineWorkfileContentDetails");
                this.view = chorus.views.WorkfileContentDetails.buildFor(this.model);
            });

            it("instantiates an AlpineWorkfileContentDetails view", function() {
                expect(this.view).toBeA(chorus.views.AlpineWorkfileContentDetails);
            });
        });

        context("when the given workfile is an Tableau file", function() {
            beforeEach(function() {
                this.model = backboneFixtures.workfile.tableau();
                spyOn(chorus.views, "TableauWorkfileContentDetails");
                this.view = chorus.views.WorkfileContentDetails.buildFor(this.model);
            });

            it("instantiates an TableauWorkfileContentDetails view", function() {
                expect(this.view).toBeA(chorus.views.TableauWorkfileContentDetails);
            });
        });

        context("when the workfile is a binary file", function() {
            beforeEach(function() {
                this.model = backboneFixtures.workfile.binary();
                this.view = chorus.views.WorkfileContentDetails.buildFor(this.model);
            });

            it("instantiates a BinaryWorkfileContentDetails view", function() {
                expect(this.view).toBeA(chorus.views.BinaryWorkfileContentDetails);
            });
        });

        context("when given anything else", function() {
            beforeEach(function() {
                this.model = backboneFixtures.workfile.text();
                this.view = chorus.views.WorkfileContentDetails.buildFor(this.model);
            });

            it("instantiates an WorkfileContentDetails view", function() {
                expect(this.view).toBeA(chorus.views.WorkfileContentDetails);
            });
        });
    });

    describe("custom scrolling", function() {
        beforeEach(function() {
            this.model = backboneFixtures.workfile.text();
            this.view = chorus.views.WorkfileContentDetails.buildFor(this.model);
            spyOn(this.view, "scrollHandler");
            this.view.render();
        });
        it("handles scrolling (to anchor content details to the top of the window when scrolling down)", function() {
            $(window).trigger("scroll");
            expect(this.view.scrollHandler).toHaveBeenCalled();
        });
        it("only binds scroll handling once", function() {
            this.view.render();
            this.view.render();
            $(window).trigger("scroll");
            expect(this.view.scrollHandler.calls.count()).toBe(1);
        });
    });

    describe("#render", function() {
        beforeEach(function() {
            this.saveFileMenu = stubQtip(".save_as");
            this.view = new chorus.views.WorkfileContentDetails({model: this.model});
            this.view.render();
        });

        context("if the user can update and if the workspace is not archived.", function() {
            beforeEach(function() {
                spyOn(this.workspace, "isActive").andReturn(true);
                spyOn(this.workspace, "canUpdate").andReturn(true);
                this.view.render();
            });

            it("has the save_as button in the details bar", function() {
                expect(this.view.$("button.save_as")).toExist();
                expect(this.view.$("button.save_as")).toContainTranslation('workfile.content_details.save_as');
            });

            it("should not have disabled class from the save as link", function() {
                expect(this.view.$(".save_as")).not.toBeDisabled();
            });

            it("should not display the autosave text", function() {
                expect(this.view.$("span.auto_save")).toHaveClass("hidden");
            });
        });

        context("if the user can't update", function() {
            beforeEach(function() {
                spyOn(this.workspace, "isActive").andReturn(true);
                spyOn(this.workspace, "canUpdate").andReturn(false);
                this.view.render();
            });

            it("does not have the save_as button in the details bar", function() {
                expect(this.view.$("button.save_as")).toBeDisabled();
            });
        });

        context("menus", function() {
            it("when replacing the current version, it should trigger the file:replaceCurrentVersion event", function() {
                spyOn(chorus.PageEvents, "trigger");
                this.view.replaceCurrentVersion();
                expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("file:replaceCurrentVersion");
            });

            it("when creating a new version, it should trigger the file:createNewVersion event", function() {
                spyOn(chorus.PageEvents, "trigger");
                this.view.createNewVersion();
                expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("file:createNewVersion");
            });
        });

        context("when the workspace is archived", function() {
            beforeEach(function() {
                this.model.workspace().set({ archivedAt: "2012-05-08 21:40:14" });
                this.view.render();
            });

            it("should disable the save button", function() {
                expect(this.view.$(".save_as")).toBeDisabled();
            });
        });

        context("when user is editing the file", function() {
            context("and the autosave event is fired", function() {
                beforeEach(function() {
                    chorus.PageEvents.trigger("file:autosaved");
                });

                it("should display the autosave text", function() {
                    expect(this.view.$("span.auto_save")).not.toHaveClass("hidden");
                });

                context("and the save as current button is clicked", function() {
                    beforeEach(function() {
                        this.view.$(".save_as").click();
                        this.saveFileMenu.find('a[data-menu-name="replace"]').click();
                    });

                    it("should display the 'Saved at' text", function() {
                        expect(this.view.$("span.auto_save").text()).toContain("Saved at");
                    });
                });
            });

            context("when the user clicks on the 'save as' button", function() {
                context("when the workfile is the most recent version", function() {
                    beforeEach(function() {
                        this.view.render();
                        this.view.$(".save_as").click();
                    });

                    it("displays the tooltip", function() {
                        expect(this.saveFileMenu).toHaveVisibleQtip();
                    });

                    it("renders the menu links", function() {
                        expect(this.saveFileMenu).toContainTranslation("workfile.content_details.replace_current");
                        expect(this.saveFileMenu).toContainTranslation("workfile.content_details.save_new_version");
                        expect(this.saveFileMenu.find("a")).not.toHaveAttr("disabled");
                    });
                });

                context("when the workfile is not the most recent version", function() {
                    beforeEach(function() {
                        this.view.model.set({ versionInfo: { id: 1 }, latestVersionId: 2 });
                        this.view.render();
                        this.view.$(".save_as").click();
                    });

                    it("displays the tooltip", function() {
                        expect(this.saveFileMenu).toHaveVisibleQtip();
                    });

                    it("disables the link to replace version", function() {
                        expect(this.saveFileMenu.find("a[data-menu-name='replace']")).toHaveAttr("disabled");
                    });
                });
            });
        });
    });
});
