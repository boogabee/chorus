describe("chorus.dialogs.ChangeWorkFlowExecutionLocation", function() {
    beforeEach(function() {
        this.model = backboneFixtures.workfile.alpine();
        this.dialog = new chorus.dialogs.ChangeWorkFlowExecutionLocation({ model: this.model });
        this.dialog.render();
    });

    describe("#render", function () {
        it("has the right title", function () {
            expect(this.dialog.$(".dialog_header h1")).toContainTranslation("work_flows.change_execution_location.title");
        });

        it("has the right label text", function(){
            expect(this.dialog.$el).toContainTranslation("work_flows.new_dialog.info");
        });

        it("has a Save Search Path button", function () {
            expect(this.dialog.$("button.submit")).toContainTranslation("work_flows.change_execution_location.save");
        });

        it("has a Cancel button", function () {
            expect(this.dialog.$("button.cancel")).toContainTranslation("actions.cancel");
        });
    });

    context("an oracle database", function () {
        beforeEach(function () {
            this.executionLocations = [backboneFixtures.oracleDataSource({id: 9910})];
            this.model.set('executionLocations', this.executionLocations);
            this.dialog = new chorus.dialogs.ChangeWorkFlowExecutionLocation({ model: this.model });
            this.dialog.render();
        });

        context("pre-populating", function() {
            it("passes the oracle data source to the picker", function() {
                expect(this.dialog.executionLocationList.getSelectedLocations()[0].id).toEqual(this.executionLocations[0].get('id'));
                expect(this.dialog.executionLocationList.getSelectedLocations()[0]).toBeA(chorus.models.OracleDataSource);
            });
        });
    });

    context("a gpdb database", function() {
        beforeEach(function() {
            this.executionLocations = [backboneFixtures.database({id: 321})];
            this.model.set('executionLocations', this.executionLocations);
            this.dialog = new chorus.dialogs.ChangeWorkFlowExecutionLocation({ model: this.model });
            this.dialog.render();
        });

        context("pre-populating", function() {
            it("passes the database and the gpdb data source to the picker", function() {
                expect(this.dialog.executionLocationList.getSelectedLocations()[0].id).toEqual(this.executionLocations[0].get('id'));
                expect(this.dialog.executionLocationList.getSelectedLocations()[0]).toBeA(chorus.models.Database);
            });
        });

        context("saving", function() {
            beforeEach(function() {
                this.model.set("hdfs_data_source_id", "not_empty");
                spyOn(this.model, "save").andCallThrough();
                spyOn(this.dialog.executionLocationList, "ready").andReturn(true);
                spyOn(this.dialog, "closeModal");
                this.dialog.$("button.submit").click();
            });

            it("puts the button in 'loading' mode", function() {
                expect(this.dialog.$("button.submit").isLoading()).toBeTruthy();
                expect(this.dialog.$("button.submit")).toContainTranslation("actions.saving");
            });

            it("saves the model", function(){
                expect(this.server.lastUpdate().json()["workfile"]["execution_locations"][0]["id"]).toEqual(this.executionLocations[0].id);
                expect(this.server.lastUpdate().json()["workfile"]["execution_locations"][0]["entity_type"]).toEqual('gpdb_database');
            });

            context("when save succeeds", function(){
                beforeEach(function() {
                    this.server.completeUpdateFor(this.model, _.extend(this.model.attributes, {executionLocation: this.executionLocations[0].attributes}));
                });

                it("dismisses the dialog", function(){
                    expect(this.dialog.closeModal).toHaveBeenCalled();
                });
            });

            context('when the save fails', function(){
                beforeEach(function() {
                    spyOn(this.dialog, "showErrors");
                    this.server.lastUpdateFor(this.model).failForbidden({message: "Forbidden"});
                });

                it("shows an error message", function() {
                    expect(this.dialog.showErrors).toHaveBeenCalledWith(this.model);
                });

                it("doesn't close the dialog box", function () {
                    this.dialog.model.trigger("savedFailed");
                    expect(this.dialog.closeModal).not.toHaveBeenCalled();
                });
            });
        });
    });

    context("an hdfs data source", function() {
        beforeEach(function() {
            this.executionLocations = [backboneFixtures.hdfsDataSource({id: 123})];
            this.model.set('executionLocations', this.executionLocations);
            this.dialog = new chorus.dialogs.ChangeWorkFlowExecutionLocation({ model: this.model });
            this.dialog.render();
        });

        context("pre-populating", function() {
            it("only passes the data source to the picker", function() {
                expect(this.dialog.executionLocationList.options.pickerOptionSet[0].database).toBeUndefined();
                expect(this.dialog.executionLocationList.options.pickerOptionSet[0].dataSource.attributes).toEqual(this.executionLocations[0].attributes);
                expect(this.dialog.executionLocationList.options.pickerOptionSet[0].dataSource).toBeA(chorus.models.HdfsDataSource);
            });
        });

        context("saving", function() {
            beforeEach(function() {
                this.model.set("database_id", "NOT_EMPTY");
                spyOn(this.model, "save").andCallThrough();
                spyOn(this.dialog.executionLocationList, "ready").andReturn(true);
                spyOn(this.dialog, "closeModal");
                this.dialog.$("button.submit").click();
            });

            it("puts the button in 'loading' mode", function() {
                expect(this.dialog.$("button.submit").isLoading()).toBeTruthy();
                expect(this.dialog.$("button.submit")).toContainTranslation("actions.saving");
            });

            it("saves the model", function(){
                expect(this.server.lastUpdate().json()["workfile"]["execution_locations"][0]["id"]).toEqual(this.executionLocations[0].id);
                expect(this.server.lastUpdate().json()["workfile"]["execution_locations"][0]["entity_type"]).toEqual('hdfs_data_source');
            });

            context("when save succeeds", function(){
                beforeEach(function() {
                    this.server.completeUpdateFor(this.model, _.extend(this.model.attributes, {executionLocation: this.executionLocations[0].attributes}));
                });

                it("dismisses the dialog", function(){
                    expect(this.dialog.closeModal).toHaveBeenCalled();
                });
            });

            context('when the save fails', function(){
                beforeEach(function() {
                    spyOn(this.dialog, "showErrors");
                    this.server.lastUpdateFor(this.model).failForbidden({message: "Forbidden"});
                });

                it("shows an error message", function() {
                    expect(this.dialog.showErrors).toHaveBeenCalledWith(this.model);
                });

                it("doesn't close the dialog box", function () {
                    this.dialog.model.trigger("savedFailed");
                    expect(this.dialog.closeModal).not.toHaveBeenCalled();
                });
            });
        });
    });

    context("when the model has no executionLocation", function () {
        beforeEach(function () {
            this.model = backboneFixtures.workfile.alpine({executionLocations: []});
            this.dialog = new chorus.dialogs.ChangeWorkFlowExecutionLocation({ model: this.model });
            this.dialog.render();
        });

        it("renders an unselected picker", function () {
            expect(this.dialog.executionLocationList.ready()).toBeFalsy();
        });
    });

    context("when the model has multiple execution locations", function () {
        beforeEach(function () {
            this.model = backboneFixtures.workfile.alpineMultiDataSourceFlow();
            this.dialog = new chorus.dialogs.ChangeWorkFlowExecutionLocation({ model: this.model });
            this.dialog.render();
        });

        it("shows all the selections on load", function () {
            expect(this.dialog.$('.execution_location_picker').length).toEqual(this.model.get('executionLocations').length);
        });
    });

    context("when the picker is not ready", function () {
        beforeEach(function () {
            spyOn(this.dialog.executionLocationList, "ready").andReturn(false);
            this.dialog.executionLocationList.trigger("change");
        });

        it("disables the save button", function () {
            expect(this.dialog.$("button.submit")).toBeDisabled();
        });
    });

    context("when the picker is ready", function () {
        beforeEach(function () {
            spyOn(chorus.PageEvents, "trigger").andCallThrough();
            spyOn(this.dialog.executionLocationList, "ready").andReturn(true);
            this.dialog.executionLocationList.trigger("change");
        });

        it("enables the save button", function () {
            expect(this.dialog.$("button.submit")).toBeEnabled();
        });
    });

    context("when the picker triggers an error", function() {
        beforeEach(function() {
            var modelWithError = backboneFixtures.database();
            modelWithError.serverErrors = { fields: { a: { BLANK: {} } } };
            this.dialog.executionLocationList.trigger("error", modelWithError);
        });

        it("shows the error", function() {
            expect(this.dialog.$('.errors')).toContainText("A can't be blank");
        });

        context("and then the picker triggers clearErrors", function(){
            it("clears the errors", function() {
                this.dialog.executionLocationList.trigger("clearErrors");
                expect(this.dialog.$('.errors')).toBeEmpty();
            });
        });
    });
});
