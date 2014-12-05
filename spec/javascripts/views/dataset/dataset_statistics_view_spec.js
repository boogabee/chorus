describe("chorus.views.DatasetStatistics", function() {
    context("for a DB Dataset", function () {
        beforeEach(function() {
            this.dataset = backboneFixtures.workspaceDataset.datasetTable();
            this.view = new chorus.views.DatasetStatistics({ model: this.dataset });
            this.view.render();
        });

        describe("when the model received an 'invalidated' trigger", function() {
            it("reloads the model", function() {
                this.dataset.trigger('invalidated');
                expect(this.dataset.statistics()).toHaveBeenFetched();
            });
        });

        it("fetches the statistics for the dataset", function() {
            expect(this.dataset.statistics()).toHaveBeenFetched();
        });

        context("when the statistics arrive", function() {
            beforeEach(function() {
                this.stats = this.dataset.statistics();
                this.stats.set({
                    rows: 0,
                    columns: 0,
                    lastAnalyzedTime: "2011-12-12 12:34:56",
                    onDiskSize: "1300000000",
                    description: "foo",
                    objectType: "BASE_TABLE",
                    partitions: 0
                });
                this.server.completeFetchFor(this.stats);
            });

            it("displays the dataset's name", function() {
                expect(this.view.$(".table_name").text()).toBe(this.dataset.get("objectName"));
            });

            it("displays the dataset's translated type", function() {
                expect(this.view.$(".table_type").text()).toBe(Handlebars.helpers.humanizedDatasetType(this.dataset.attributes, this.dataset.statistics()));
            });

            it("displays rows when the value is 0", function() {
                expect(this.view.$(".statistics .rows .value").text().trim()).toBe("0");
            });

            it("displays columns when the value is 0", function() {
                expect(this.view.$(".statistics .columns .value").text().trim()).toBe("0");
            });

            it("displays the on disk size", function() {
                expect(this.view.$(".size .value").text().trim()).toBe("1 GB");
            });

            it("displays the description", function() {
                expect(this.view.$(".description p").text().trim()).toBe("foo");
            });

            it("displays the last analyzed time", function() {
                expect(this.view.$(".last_analyzed_time .value").text()).toBe(Handlebars.helpers.relativeTimestamp(this.stats.get("lastAnalyzedTime")));
            });


            describe("when the partitions are 0", function() {
                beforeEach(function() {
                    this.stats.set({ partitions: 0 });
                    this.view.render();
                });

                it("should not show the partitions pair", function() {
                    expect(this.view.$(".partitions")).not.toExist();
                });

                it("displays the statistics in the correct order", function() {
                    expect(this.view.$(".statistics .pair").eq(0).find(".key").text().trim()).toMatchTranslation("dataset.statistics.type");
                    expect(this.view.$(".statistics .pair").eq(1).find(".key").text().trim()).toMatchTranslation("dataset.statistics.columns");
                    expect(this.view.$(".statistics .pair").eq(2).find(".key").text().trim()).toMatchTranslation("dataset.statistics.last_analyzed_time");
                    expect(this.view.$(".statistics .pair").eq(3).find(".key").text().trim()).toMatchTranslation("dataset.statistics.rows");
                    expect(this.view.$(".statistics .pair").eq(4).find(".key").text().trim()).toMatchTranslation("dataset.statistics.size");
                });
            });

            describe("when the partitions are greater than 0", function() {
                beforeEach(function() {
                    this.stats.set({ partitions: 10 });
                    this.view.render();
                });

                it("displays the partitions", function() {
                    expect(this.view.$(".partitions .value").text()).toBe("10");
                });

                it("should not show the rows pair", function() {
                    expect(this.view.$(".rows")).not.toExist();
                });

                it("displays the statistics in the correct order", function() {
                    expect(this.view.$(".statistics .pair").eq(0).find(".key").text().trim()).toMatchTranslation("dataset.statistics.type");
                    expect(this.view.$(".statistics .pair").eq(1).find(".key").text().trim()).toMatchTranslation("dataset.statistics.partitions");
                    expect(this.view.$(".statistics .pair").eq(2).find(".key").text().trim()).toMatchTranslation("dataset.statistics.columns");
                    expect(this.view.$(".statistics .pair").eq(3).find(".key").text().trim()).toMatchTranslation("dataset.statistics.last_analyzed_time");
                    expect(this.view.$(".statistics .pair").eq(4).find(".key").text().trim()).toMatchTranslation("dataset.statistics.size");
                });
            });

            describe("when the lastAnalyzedTime is null", function() {
                beforeEach(function() {
                    this.stats.set({ lastAnalyzedTime: null, rows: 5837 });
                    this.view.render();
                });

                it("should not display the lastAnalyzedTime or row count", function() {
                    expect(this.view.$(".rows")).not.toExist();
                    expect(this.view.$(".last_analyzed_time")).not.toExist();
                });
            });

            describe("when the statistics are re-fetched", function() {
                it("re-renders", function() {
                    spyOn(this.view, 'postRender');
                    this.stats.fetch();
                    this.server.completeFetchFor(this.stats);
                    expect(this.view.postRender).toHaveBeenCalled();
                });
            });
        });
    });

    context("for a HDFS Dataset", function () {
        beforeEach(function() {
            this.dataset = backboneFixtures.workspaceDataset.hdfsDataset();
            this.view = new chorus.views.DatasetStatistics({ model: this.dataset });
            this.view.render();
        });

        describe("when the model received an 'invalidated' trigger", function() {
            it("reloads the model", function() {
                this.dataset.trigger('invalidated');
                expect(this.dataset.statistics()).toHaveBeenFetched();
            });
        });

        it("fetches the statistics for the dataset", function() {
            expect(this.dataset.statistics()).toHaveBeenFetched();
        });

        context("when the statistics arrive", function() {
            beforeEach(function() {
                this.stats = this.dataset.statistics();
                this.server.completeFetchFor(this.stats, backboneFixtures.hdfsDatasetStatisticsJson().response);
            });

            it("displays the dataset's name", function() {
                expect(this.view.$(".table_name").text()).toBe(this.dataset.get("objectName"));
            });

            it("displays the dataset's file_mask", function() {
                expect(this.view.$(".file_mask .value").text()).toBe(this.dataset.get("fileMask"));
            });

            it("displays the dataset's translated type", function() {
                var humanizedDatasetType = Handlebars.helpers.humanizedDatasetType(this.dataset.attributes, this.dataset.statistics());
                var text = this.view.$(".table_type").text();

                expect(text).not.toMatchTranslation("loading");
                expect(text).toBe(humanizedDatasetType);
            });

            describe("when the statistics are re-fetched", function() {
                it("re-renders", function() {
                    spyOn(this.view, 'postRender');
                    this.stats.fetch();
                    this.server.completeFetchFor(this.stats);
                    expect(this.view.postRender).toHaveBeenCalled();
                });
            });
        });
    });
});
