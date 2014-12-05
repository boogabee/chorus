describe("chorus.views.LocationPicker.DataSourceView", function() {

    beforeEach(function() {
        this.gpdbDataSource = backboneFixtures.gpdbDataSource();
        this.hdfsDataSource = backboneFixtures.hdfsDataSource();
        this.oracleDataSource = backboneFixtures.oracleDataSource();
    });

    context("when 'showHdfsDataSources' is true", function() {
        beforeEach(function() {
            this.databasePicker = jasmine.createSpyObj('DatabaseView', ['hide', 'isHidden']);
            this.view = new chorus.views.LocationPicker.DataSourceView({
                showHdfsDataSources: true,
                childPicker: this.databasePicker
            });
        });

        it("should fetch both hdfs and gpdb data sources", function() {
            expect(this.server.requests.length).toBe(2);
        });

        it("adds the 'jobTracker' param to the hdfs data source set", function() {
            expect(this.view.hdfsDataSources.attributes.jobTracker).toBeTruthy();
        });

        context("selecting an HDFS data source", function() {
            beforeEach(function() {
                this.server.completeFetchAllFor(this.view.pgGpDataSources, [this.gpdbDataSource]);
                this.server.completeFetchAllFor(this.view.hdfsDataSources, [this.hdfsDataSource]);
                this.view.render();
                this.databasePicker.hide.reset();
                this.view.$('select').val(this.hdfsDataSource.get('id')).change();
            });

            it("hides the database selector", function() {
                expect(this.databasePicker.hide).toHaveBeenCalled();
            });
        });
    });

    context("when 'showAllDbDataSources' is true", function() {
        beforeEach(function() {
            this.databasePicker = jasmine.createSpyObj('DatabaseView', ['hide', 'isHidden', 'parentSelected']);
            this.view = new chorus.views.LocationPicker.DataSourceView({
                showAllDbDataSources: true,
                childPicker: this.databasePicker
            });
        });

        it("should fetch all data source entity types", function() {
            expect(this.server.requests.length).toBe(1);
            expect(this.server.requests[0].params()['entity_type']).toBeUndefined();
        });

        context("selecting an oracle data source", function() {
            beforeEach(function() {
                this.server.completeFetchAllFor(this.view.databaseDataSources, [this.gpdbDataSource, this.oracleDataSource]);
                this.view.render();
                this.databasePicker.parentSelected.reset();
                this.view.$('select').val(this.oracleDataSource.get('id')).change();
            });

            it("hides the database selector", function() {
                expect(this.databasePicker.parentSelected).toHaveBeenCalled();
            });
        });
    });
    
    context("when 'showHdfsDataSources' is false", function() {
        beforeEach(function() {
            this.view = new chorus.views.LocationPicker.DataSourceView({
                showHdfsDataSources: false
            });
            this.server.completeFetchAllFor(this.view.pgGpDataSources, [this.gpdbDataSource]);
        });

        it("should fetch only gpdb data sources", function() {
            expect(this.server.requests.length).toBe(1);
        });

        it("it should only show the gpdb data sources", function() {
            expect(this.view.collection.length).toBeGreaterThan(0);
            this.view.collection.each(function(dataSource) {
                expect(dataSource.entityType).toBe("gpdb_data_source");
            });
        });
    });

    context("when there is a default data source", function() {
        beforeEach(function() {
            var childPicker = new chorus.views.LocationPicker.DatabaseView();
            this.view = new chorus.views.LocationPicker.DataSourceView({
                showHdfsDataSources: false,
                childPicker: childPicker
            });
            this.view.setSelection(this.gpdbDataSource);
            this.server.completeFetchAllFor(this.view.pgGpDataSources, [this.gpdbDataSource]);
            this.view.render();
        });

        it("should pre-populate the selector", function() {
            expect(this.view.getSelectedDataSource().get("id")).toBe(this.gpdbDataSource.id);
            expect(this.view.getSelectedDataSource().get("entityType")).toBe(this.gpdbDataSource.entityType);
        });
    });
});
