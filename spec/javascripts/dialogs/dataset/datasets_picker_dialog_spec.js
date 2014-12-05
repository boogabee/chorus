describe("chorus.dialogs.DatasetsPicker", function() {
    var dialog, datasets, datasetModels;
    beforeEach(function() {
        stubModals();
        datasets = new chorus.collections.WorkspaceDatasetSet([], {workspaceId: "33", type: "SANDBOX_TABLE", objectType: "TABLE" });
        dialog = new chorus.dialogs.DatasetsPicker({ collection: datasets });
        datasetModels = [
            backboneFixtures.workspaceDataset.datasetTable({ objectName: "A", id: "REAL_ID" }),
            backboneFixtures.workspaceDataset.datasetTable({ objectName: "B", id: "AGENT_SMITH" })
        ];
    });

    describe("#render", function() {
        var options;
        beforeEach(function() {
            options = { order: "objectName", entitySubtype: "SANDBOX_TABLE" };
            dialog.launchModal();
        });

        it("fetches the results sorted by objectName", function() {
            var url = this.server.lastFetch().url;
            var urlParams = _.extend({}, options);
            urlParams.order = "object_name";
            expect(url).toHaveUrlPath("/workspaces/33/datasets");
            expect(url).toContainQueryParams(urlParams);
        });

        describe("when the fetch completes", function() {
            beforeEach(function() {
                this.server.completeFetchFor(datasets, datasetModels, options);
                spyOn(chorus.dialogs.PreviewColumns.prototype, 'render').andCallThrough();
            });

            it("shows the correct title", function() {
                expect(dialog.$("h1")).toContainTranslation("dataset.pick_destination");
            });

            it("shows the correct search help", function() {
                expect(dialog.$("input.chorus_search").attr("placeholder")).toMatchTranslation("dataset.dialog.search_table");
            });

            it("shows the correct item count label", function() {
                expect(dialog.$(".count")).toContainTranslation("entity.name.Table", { count: 2 });
            });

            it("shows the correct button name", function() {
                expect(dialog.$("button.submit")).toContainTranslation("actions.dataset_select");
            });

            it("doesn't have multiSelection", function() {
                expect(dialog.multiSelection).toBeFalsy();
            });

            it("only shows real sandbox tables (no hdfs, source, externals, views)", function() {
                _.each(dialog.collection.models, function(model) {
                    expect(model.get("entitySubtype")).toBe("SANDBOX_TABLE");
                });
            });

            it("shows a Preview Columns link for each dataset", function() {
                expect(dialog.$("ul li:eq(0) a.preview_columns")).toContainTranslation("dataset.manage_join_tables.preview_columns");
                expect(dialog.$("ul li:eq(1) a.preview_columns")).toContainTranslation("dataset.manage_join_tables.preview_columns");
            });

            it("has the correct id, not the CID", function() {
                expect(dialog.$("ul li:eq(0)").data("id")).toBe("REAL_ID");
                expect(dialog.$("ul li:eq(1)").data("id")).toBe("AGENT_SMITH");
            });

            it("shows the preview columns submodal with the appropriate dataset when you click the link", function() {
                dialog.$("ul li:eq(0) a.preview_columns").click();
                expect(chorus.dialogs.PreviewColumns.prototype.render).toHaveBeenCalled();
                var previewColumnsDialog = chorus.dialogs.PreviewColumns.prototype.render.lastCall().object;
                expect(previewColumnsDialog.title).toBe(dialog.title);
                expect(previewColumnsDialog.model.get("id")).toEqual(datasetModels[0].get("id"));
            });

            describe("selecting an item", function() {
                beforeEach(function() {
                    dialog.$("ul li:eq(0)").click();
                });
                it("should mark the item selected", function() {
                    expect(dialog.$("ul li:eq(0)")).toHaveClass("selected");
                });
            });

            describe("closing the dialog", function() {
                beforeEach(function() {
                    datasets.search("searching");
                    dialog.$("button.cancel").click();
                });

                it("resets the namePattern on the collection", function() {
                    expect(datasets.attributes.namePattern).toBe("");
                });
            });
        });
    });
});
