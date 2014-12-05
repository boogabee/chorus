describe("chorus.views.HdfsEntryStatisticsView", function() {
    beforeEach(function () {
        this.hdfsEntry = backboneFixtures.hdfsFile();
        this.view = new chorus.views.HdfsEntryStatistics({model: this.hdfsEntry});
        this.view.render();
    });

    describe("when the model received an 'invalidated' trigger", function() {
        it("reloads the model", function() {
            this.hdfsEntry.trigger('invalidated');
            expect(this.hdfsEntry.statistics()).toHaveBeenFetched();
        });
    });

    it("fetches the statistics for the dataset", function() {
        expect(this.hdfsEntry.statistics()).toHaveBeenFetched();
    });

    context("when the statistics arrive", function() {
        beforeEach(function() {
            this.stats = backboneFixtures.hdfsEntryStatistics();
            this.stats.set({entryId: this.hdfsEntry.id, hdfsDataSourceId: this.hdfsEntry.get("hdfsDataSource").id});
            this.server.completeFetchFor(this.stats);
        });

        it("displays all of the non size details", function () {
            var itHasValueFor = _.bind(function (key) {
                expect(this.view.$('.' + key + ' .key')).toContainTranslation('hdfs_entry.statistics.' + key);
                expect(this.view.$('.' + key + ' .value')).toContainText(this.stats.get(_.camelize(key)));
            }, this);

            itHasValueFor('owner');
            itHasValueFor('group');
            itHasValueFor('modified_at');
            itHasValueFor('accessed_at');
            itHasValueFor('permissions');
            itHasValueFor('replication');
        });

        it("displays humanized file_size and block_size", function () {
            _.each(['file_size', 'block_size'], function (key) {
                expect(this.view.$('.' + key + ' .key')).toContainTranslation('hdfs_entry.statistics.' + key);
                expect(this.view.$('.' + key + ' .value')).toContainText(I18n.toHumanSize(this.stats.get(_.camelize(key))));
            }, this);
        });
    });
});