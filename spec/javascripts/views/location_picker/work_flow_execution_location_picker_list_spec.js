describe("chorus.views.WorkFlowExecutionLocationPickerList", function () {
    beforeEach(function () {
        this.view = new chorus.views.WorkFlowExecutionLocationPickerList();
    });

    describe("#ready", function () {
        it("is true if all subviews are ready", function () {
            _.each(this.view.pickers, function (picker) { spyOn(picker, 'ready').andReturn(true); });
            this.view.pickers[0].ready.andReturn(false);
            expect(this.view.ready()).toBeFalsy();

            this.view.pickers[0].ready.andReturn(true);
            expect(this.view.ready()).toBeTruthy();
        });
    });

    describe("change", function () {
        it("triggers when any of the pickers trigger change", function () {
            spyOn(this.view, 'trigger');

            this.view.pickers[0].trigger('change');

            expect(this.view.trigger).toHaveBeenCalledWith('change');
        });
    });

    describe("#render", function () {
        beforeEach(function () {
            this.view.render();
        });

        context("once the fetches complete", function () {
            beforeEach(function () {
                this.server.completeFetchFor(this.view.pickers[0].dataSourceView.hdfsDataSources, [backboneFixtures.hdfsDataSource()]);
                this.server.completeFetchFor(this.view.pickers[0].dataSourceView.databaseDataSources, [backboneFixtures.gpdbDataSource({ id: "5" })]);
                this.view.$('select[name="data_source"]').val("5GpdbDataSource").change();
                var databases = new chorus.collections.DatabaseSet([backboneFixtures.database()]);
                this.server.completeFetchFor(this.view.pickers[0].databaseView.collection, databases);
            });

            it("renders all the pickers", function () {
                expect(this.view.$el).toContainTranslation("sandbox.select.data_source");
            });

            it("displays a link to add a row", function () {
                expect(this.view.$('a.add_source')).toExist();
                expect(this.view.$('a.add_source')).toContainTranslation('work_flows.change_execution_location.add_source');
            });

            it("displays a 'remove' link on every row but the first one", function () {
                this.view.$('.add_source').click();
                expect(this.view.$('.execution_location_picker:eq(0) .remove_source')).not.toExist();
                expect(this.view.$('.execution_location_picker:eq(1) .remove_source')).toExist();
            });

            describe("clicking 'add source'", function () {
                beforeEach(function () {
                    this.currentSources = this.view.$('.execution_location_picker').length;
                });

                it('adds another pair', function () {
                    this.view.$('.add_source').click();
                    expect(this.view.$('.execution_location_picker').length).toBe(this.currentSources + 1);
                });

                it("keeps the selection of the other pickers", function () {
                    this.view.$('.add_source').click();
                    var dataSourceSelection = this.view.$('select[name="data_source"]').eq(0).children(':selected').text();
                    expect(dataSourceSelection).toBe(backboneFixtures.gpdbDataSource().get('name'));
                });
            });

            describe("clicking 'remove source'", function () {
                beforeEach(function () {
                    this.view.$('.add_source').click();
                    this.currentSources = this.view.$('.execution_location_picker').length;
                });

                it('removes the adjacent picker', function () {
                    this.view.$('.execution_location_picker:eq(1) .remove_source').click();
                    expect(this.view.$('.execution_location_picker').length).toBe(this.currentSources - 1);
                });

                it("keeps the selection of the other pickers", function () {
                    this.view.$('.execution_location_picker:eq(1) .remove_source').click();
                    var dataSourceSelection = this.view.$('select[name="data_source"]').eq(0).children(':selected').text();
                    expect(dataSourceSelection).toBe(backboneFixtures.gpdbDataSource().get('name'));
                });

                it("retriggers form validation", function () {
                    spyOn(this.view, 'trigger');
                    this.view.$('.remove_source').eq(0).click();
                    expect(this.view.trigger).toHaveBeenCalledWith('change');
                });

            });

            describe("getSelectedLocations", function () {
                beforeEach(function () {
                    this.selectedDataSource = backboneFixtures.hdfsDataSource();
                    this.view.$('.add_source').click();
                    this.view.pickers[0].dataSourceView.setSelection(this.selectedDataSource);
                    this.view.pickers[1].dataSourceView.setSelection(backboneFixtures.gpdbDataSource());
                    this.view.pickers[1].databaseView.setSelection(backboneFixtures.database());
                    this.view.$('.execution_location_picker:eq(1) .remove_source').click();
                });

                it("returns only dataSources that are currently selected", function () {
                    expect(this.view.getSelectedLocations()).toEqual([this.selectedDataSource]);
                });
            });
        });
    });
});
