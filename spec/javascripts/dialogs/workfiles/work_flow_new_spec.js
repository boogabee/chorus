describe("chorus.dialogs.WorkFlowNew", function() {
    beforeEach(function() {
        this.workspace = backboneFixtures.workspace();
        this.sandboxDatabase = this.workspace.sandbox().database();
        this.dialog = new chorus.dialogs.WorkFlowNew({pageModel: this.workspace});
        this.dialog.render();
    });

    it("has the right title", function() {
        expect(this.dialog.$(".dialog_header h1")).toContainTranslation("work_flows.new_dialog.title");
    });

    it("has an Add Work Flow button", function() {
        expect(this.dialog.$("button.submit")).toContainTranslation("work_flows.new_dialog.add_work_flow");
    });

    it("shows some instructional text", function () {
        expect(this.dialog.$el).toContainTranslation("work_flows.new_dialog.info");
    });

    it("creates a location picker with the schema section hidden", function(){
        expect(this.dialog.$('.schema')).not.toExist();
    });

    context("when the workspace has a sandbox", function() {
        it("sets the default data source and database for the picker list", function() {
            expect(this.sandboxDatabase).toBeTruthy();
            expect(this.dialog.executionLocationList.options.database).toEqual(this.sandboxDatabase);
            expect(this.dialog.executionLocationList.options.dataSource).toEqual(this.sandboxDatabase.dataSource());
        });
    });

    context("when the workspace does not have a sandbox", function() {
        beforeEach(function() {
            this.workspace._sandbox = null;
            this.workspace.set('sandboxInfo', null);
            this.dialog = new chorus.dialogs.WorkFlowNew({pageModel: this.workspace});
            this.dialog.render();
        });

        it("does not set a default data source or database", function() {
            expect(this.dialog.executionLocationList.options.database).toBeFalsy();
            expect(this.dialog.executionLocationList.options.dataSource).toBeFalsy();
        });
    });

    describe("submitting", function() {
        beforeEach(function() {
            spyOn(this.dialog.executionLocationList, "ready").andReturn(true);
            this.dialog.executionLocationList.trigger('change');
            spyOn(this.dialog.executionLocationList, 'getSelectedLocations');
        });

        describe("with valid form values", function() {
            beforeEach(function() {
                this.dialog.$("input[name='fileName']").val("stuff").keyup();
            });

            it("enables the submit button", function() {
                expect(this.dialog.$("form button.submit")).not.toBeDisabled();
            });

            describe("selecting a gpdb data source", function() {
                beforeEach(function() {
                    this.dialog.executionLocationList.getSelectedLocations.andReturn([this.sandboxDatabase]);
                });

                it("submits the form with the right parameters", function() {
                    this.dialog.$("form").submit();
                    var json = this.server.lastCreate().json()["workfile"];
                    expect(json["entity_subtype"]).toEqual('alpine');
                    expect(json["execution_locations"][0]["id"]).toEqual(this.sandboxDatabase.id);
                    expect(json["execution_locations"][0]["entity_type"]).toEqual('gpdb_database');
                });

                describe("when the workfile creation succeeds", function() {
                    beforeEach(function() {
                        spyOn(this.dialog, "closeModal");
                        spyOn(chorus.router, "navigate");
                        spyOn(this.dialog.model, "notifyWorkflowLimitedDataSource");
                        this.dialog.$("form").submit();
                        this.server.completeCreateFor(this.dialog.resource, {id: 42});
                    });

                    it("closes the dialog", function() {
                        expect(this.dialog.closeModal).toHaveBeenCalled();
                    });

                    it("checks for limited data sources", function() {
                        expect(this.dialog.model.notifyWorkflowLimitedDataSource).toHaveBeenCalled();
                    });

                    it("navigates to the workflow page", function() {
                        expect(chorus.router.navigate).toHaveBeenCalledWith("#/work_flows/42");
                    });
                });

                describe("when the save fails", function() {
                    beforeEach(function() {
                        spyOn($.fn, 'stopLoading');
                        this.dialog.$("form").submit();
                        this.server.lastCreateFor(this.dialog.model).failUnprocessableEntity();
                    });

                    it("removes the spinner from the button", function() {
                        expect($.fn.stopLoading).toHaveBeenCalledOnSelector("button.submit");
                    });

                    it("does not erase the fileName input", function() {
                        expect(this.dialog.$("input[name='fileName']").val()).toBe("stuff");
                    });
                });
            });

            context("when selecting hdfs data source", function() {
                beforeEach(function() {
                    this.hdfsDataSource = backboneFixtures.hdfsDataSource({id: '123Garbage'});
                    this.dialog.executionLocationList.getSelectedLocations.andReturn([this.hdfsDataSource]);
                });

                it("submits the form with the right parameters", function() {
                    this.dialog.$('form').submit();
                    var json = this.server.lastCreate().json()["workfile"];
                    expect(json["entity_subtype"]).toEqual('alpine');
                    expect(json["execution_locations"][0]["id"]).toEqual(this.hdfsDataSource.get('id'));
                    expect(json["execution_locations"][0]["entity_type"]).toEqual('hdfs_data_source');
                });
            });
        });

        describe("when the location picker is not ready", function() {
            it("disables the form", function() {
                this.dialog.executionLocationList.ready.andReturn(false);
                this.dialog.executionLocationList.trigger('change');

                expect(this.dialog.$("form button.submit")).toBeDisabled();
            });
        });

        describe("with an invalid work flow name", function() {
            it("does not allow submitting", function() {
                this.dialog.$("input[name='fileName']").val("     ").keyup();
                expect(this.dialog.$("form button.submit")).toBeDisabled();
            });
        });
    });
});
