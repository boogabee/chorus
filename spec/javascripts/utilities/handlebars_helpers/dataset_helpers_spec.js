describe('chorus.handlebarsHelpers.dataset', function() {
    describe("chooserMenu", function () {
        it("has a limiter class", function () {
            var html = Handlebars.compile("{{chooserMenu false max=1}}")();
            var chooser = $(html);
            expect(chooser).toHaveClass('limiter');
        });

        it("sets the className if provided", function () {
            var html = Handlebars.compile('{{chooserMenu false max=3 className="foo"}}')();
            var chooser = $(html);
            expect(chooser).toHaveClass('foo');
        });

        context("when an array of choices is specified", function () {
            var chooser;

            beforeEach(function () {
                var choices = ["foo", "bar", "baz"];
                var html = Handlebars.compile("{{chooserMenu choices}}")({ choices:choices });
                chooser = $(html);
            });

            it("uses the specified choices", function () {
                expect(chooser.find('.limiter_menu_container ul.limiter_menu li').length).toBe(3);
                expect(chooser.find('li').eq(0)).toContainText('foo');
                expect(chooser.find('li').eq(1)).toContainText('bar');
                expect(chooser.find('li').eq(2)).toContainText('baz');
            });

            it("uses the last choice by default", function () {
                expect(chooser.find('a')).toContainText('baz');
            });
        });

        context("when no choices are specified", function () {
            it("uses an array of numbers up to the max specified", function () {
                var html = Handlebars.compile("{{chooserMenu false max=3}}")();
                var chooser = $(html);
                expect(chooser.find('.limiter_menu_container ul.limiter_menu li').length).toBe(3);
                expect(chooser.find('li').eq(0)).toContainText('1');
                expect(chooser.find('li').eq(1)).toContainText('2');
                expect(chooser.find('li').eq(2)).toContainText('3');
            });

            it("sets the default to the provided value", function () {
                var html = Handlebars.compile("{{chooserMenu false max=3 initial=2}}")();
                var chooser = $(html);
                expect(chooser.find('a')).toContainText('2');
            });

            it("sets the default to max if no default provided", function () {
                var html = Handlebars.compile("{{chooserMenu false max=3}}")();
                var chooser = $(html);
                expect(chooser.find('a')).toContainText('3');
            });
        });
    });

    describe("sqlDefinition", function () {
        it("html escapes the input", function () {
            var definition = Handlebars.helpers.sqlDefinition("<script>");
            expect(definition).not.toMatch('<script>');
        });
    });

    describe("datasetLocation", function () {
        context("for a DB object", function () {
            beforeEach(function () {
                this.model = backboneFixtures.dataset();
                this.result = Handlebars.helpers.datasetLocation(this.model).toString();
            });

            it("includes the from text", function () {
                expect($(this.result)).toContainTranslation('dataset.from', {location: ''});
            });

            it('includes the data source name, database name, and schema name', function () {
                var dataSource = this.model.dataSource();
                expect($(this.result).find("a.data_source")).toContainText(dataSource.name());
                expect($(this.result).find("a.data_source")).toHaveHref(dataSource.showUrl());

                var database = this.model.database();
                expect($(this.result).find("a.database")).toContainText(database.name());
                expect($(this.result).find("a.database")).toHaveHref(database.showUrl());

                expect($(this.result).find("a.schema")).toContainText(this.model.schema().name());
                expect($(this.result).find("a.schema").attr("href")).toMatchUrl(this.model.schema().showUrl());
            });

            it("includes the highlighted database and schema name", function () {
                var searchResult = backboneFixtures.searchResult({
                    datasets: {
                        results: [
                            {
                                schema: {
                                    highlightedAttributes: { name: ['schema_<em>name</em>'] },
                                    database: {
                                        highlightedAttributes: { name: ['db_<em>name</em>'] }
                                    }
                                }
                            }
                        ]
                    }
                });
                this.model = searchResult.datasets().at(0);
                this.result = Handlebars.helpers.datasetLocation(this.model).toString();
                expect($(this.result).find('em').length).toBe(2);
            });

            context('when the dataset schemas parent is a data source', function () {
                beforeEach(function () {
                    this.model = backboneFixtures.oracleDataset();
                    this.result = $(Handlebars.helpers.datasetLocation(this.model).toString());
                });

                it("doesn't include a database name", function () {
                    var dataSource = this.model.dataSource();
                    expect(this.result.find("a.data_source")).toContainText(dataSource.name());
                    expect(this.result.find("a.data_source")).toHaveHref(dataSource.showUrl());

                    expect(this.result.find("a.database")).not.toExist();

                    expect(this.result.find("a.schema")).toContainText(this.model.schema().name());
                    expect(this.result.find("a.schema").attr("href")).toMatchUrl(this.model.schema().showUrl());
                });
            });

            context("when the dataset's schema has not been loaded correctly", function () {
                beforeEach(function () {
                    this.model = new chorus.models.DynamicDataset();
                });

                it("returns the empty string", function () {
                    expect(Handlebars.helpers.datasetLocation(this.model).toString()).toEqual("");
                });
            });

            context("when credentials are not present", function () {
                beforeEach(function () {
                    this.model = backboneFixtures.dataset({hasCredentials: false});
                    this.result = Handlebars.helpers.datasetLocation(this.model).toString();
                });

                it('includes the data source name, database name, and schema name', function () {
                    expect($(this.result)).toContainText(this.model.dataSource().name());
                    expect($(this.result)).toContainText(this.model.database().name());
                    expect($(this.result)).toContainText(this.model.schema().name());
                    expect($(this.result).find('a')).not.toExist();
                });
            });

            context("when user provided a label", function () {
                beforeEach(function () {
                    this.model = backboneFixtures.workspaceDataset.datasetTable();
                    this.result = Handlebars.helpers.datasetLocation(this.model, 'workspace.sandbox_schema').toString();
                });

                it("includes the label text", function () {
                    expect($(this.result)).toContainTranslation('workspace.sandbox_schema', {location: ''});
                });
            });
        });

        context("for a filesystem object", function () {
            beforeEach(function () {
                this.model = backboneFixtures.workspaceDataset.hdfsDataset();
                this.result = Handlebars.helpers.datasetLocation(this.model).toString();
            });

            it("includes the from text", function () {
                expect($(this.result)).toContainTranslation('dataset.from', {location: ''});
            });

            it('includes the data source name, database name, and schema name', function () {
                var dataSource = this.model.dataSource();
                expect($(this.result).find("a.data_source")).toContainText(dataSource.name());
                expect($(this.result).find("a.data_source")).toHaveHref(dataSource.showUrl());

                expect($(this.result).find("a.database")).not.toExist();

                expect($(this.result).find("a.schema")).not.toExist();
            });
        });
    });

    describe("humanizedDatasetType", function () {
        beforeEach(function () {
            spyOn(window, "t");
        });

        context("when statistics is not present", function() {
            it("returns a loading message when dataset has not loaded", function () {
                Handlebars.helpers.humanizedDatasetType({});
                expect(window.t).toHaveBeenCalledWith("loading");
            });

            it("returns Chorus view if dataset is Chorus_view", function () {
                this.chorusView = backboneFixtures.workspaceDataset.chorusView();
                Handlebars.helpers.humanizedDatasetType(this.chorusView.attributes);
                expect(window.t).toHaveBeenCalledWith('dataset.entitySubtypes.CHORUS_VIEW.CHORUS_VIEW');
            });

            it("returns Source Table", function() {
                this.sourceTable = backboneFixtures.workspaceDataset.sourceTable();
                Handlebars.helpers.humanizedDatasetType(this.sourceTable.attributes);
                expect(window.t).toHaveBeenCalledWith('dataset.entitySubtypes.SOURCE_TABLE.TABLE');
            });

            it("returns Source View", function() {
                this.sourceView = backboneFixtures.workspaceDataset.sourceView();
                Handlebars.helpers.humanizedDatasetType(this.sourceView.attributes);
                expect(window.t).toHaveBeenCalledWith('dataset.entitySubtypes.SOURCE_TABLE.VIEW');
            });

            it("returns Sandbox Table", function() {
                this.sandBoxTable = backboneFixtures.workspaceDataset.datasetTable();
                Handlebars.helpers.humanizedDatasetType(this.sandBoxTable.attributes);
                expect(window.t).toHaveBeenCalledWith('dataset.entitySubtypes.SANDBOX_TABLE.BASE_TABLE');
            });

            it("returns Sandbox View", function() {
                this.sandBoxView = backboneFixtures.workspaceDataset.datasetView();
                Handlebars.helpers.humanizedDatasetType(this.sandBoxView.attributes);
                expect(window.t).toHaveBeenCalledWith('dataset.entitySubtypes.SANDBOX_TABLE.VIEW');
            });
        });

        context("when the statistics object is present", function() {
            it("should return a loading message if statistics has no objectType", function() {
                Handlebars.helpers.humanizedDatasetType({ type: "type" }, { otherStuff: "hi" });
                expect(window.t).toHaveBeenCalledWith("loading");
            });

            it("returns the correct dataset type translation", function() {
                Handlebars.helpers.humanizedDatasetType({ entitySubtype: "type" }, backboneFixtures.datasetStatisticsTable({ objectType: "objectType" }));
                expect(window.t).toHaveBeenCalledWith("dataset.entitySubtypes.type.objectType");
            });
        });
    });
});