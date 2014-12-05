describe("chorus.dialogs.CreateDirectoryExternalTableFromHdfs", function() {
    beforeEach(function() {

        this.collection = new chorus.collections.CsvHdfsFileSet([
            backboneFixtures.hdfsFile().attributes,
            backboneFixtures.hdfsFile().attributes,
            backboneFixtures.hdfsFile().attributes
        ], {hdfsDataSource: {id: "234"}});

        this.csvOptions = {
            contents: [
                "COL1,col2, col3 ,col 4,Col_5",
                "val1.1,val1.2,val1.3,val1.4,val1.5",
                "val2.1,val2.2,val2.3,val2.4,val2.5",
                "val3.1,val3.2,val3.3,val3.4,val3.5"
            ]
        };

        this.model = this.collection.at(0);

        this.model.set({
            hdfsDataSourceId: '234',
            path: '/file/bar.csv',
            name: 'bar.csv'
        });

        this.dialog = new chorus.dialogs.CreateDirectoryExternalTableFromHdfs({
            csvOptions: this.csvOptions,
            workspaceName: "workspace1",
            workspaceId: "22",
            directoryName: "test",
            collection: this.collection,
            hdfs_entry_id: "1"
        });
    });

    it("does not include a header row", function() {
        expect(this.dialog.includeHeader).toBeFalsy();
    });

    describe("#setup", function() {
        it("sets csv to be the first models in the collection", function() {
            expect(this.dialog.model).toEqual(this.collection.at(0));
        });
    });

    describe("#setupModel", function () {
        context("when the directory path is /", function() {
            beforeEach(function() {
                this.dialog.collection.attributes.path = "/";
                this.dialog.setupModel();
            });
            it("prevents an extra / from being included in the file path", function() {
                expect(this.dialog.model.get("path")).toBe("/bar.csv");
            });

            it("sets the hadoop data source id", function() {
                expect(this.dialog.model.get("hdfsDataSourceId")).toBe("234");
            });
        });
    });

    describe("#setupCsvOptions", function () {
        it("sets the tableName", function() {
            expect(this.dialog.csvOptions.tableName).toBe("test");
        });
    });

    describe("#render", function () {
        beforeEach(function() {
            $('#jasmine_content').append(this.dialog.el);
            this.dialog.render();
        });

        it("populates the table name with the directory name", function() {
            expect(this.dialog.$("input[name=tableName]").val()).toBe("test");
        });

        it("populates the select sample file with hdfs text files", function() {
            expect(this.dialog.$("select option").length).toBe(3);
        });

        it("selects the all files option by default", function() {
            expect(this.dialog.$('input:radio[name=pathType]:checked').val()).toBe("directory");
        });

        it("creates a textbox for the file pattern", function() {
            expect(this.dialog.$("[name=pattern]")).toExist();
        });

        describe("changing the file", function () {
            beforeEach(function() {
                spyOn(chorus, 'styleSelect');
                this.dialog.$("input[name='pattern']").val("*.csv");
                this.dialog.$("input#pattern").prop("checked", "checked").change();
                var selElement = this.dialog.$("select").val(this.collection.at(1).get("name"));
                selElement.change();
            });

            it("should fetch the new sample", function() {
                expect(this.server.lastFetch().url).toBe("/hdfs_data_sources/"+this.collection.attributes.hdfsDataSource.id+"/files/?id="+
                    this.collection.at(1).id);
            });

            it("display spinner", function() {
                expect(this.dialog.$(".import_data_grid").isLoading()).toBeTruthy();
            });

            context("when the fetch completes", function() {
                beforeEach(function() {
                    this.server.completeFetchFor(this.dialog.model, {tableName: 'new_test_name', contents: 'Undefined!'});
                });

                it("stops the spinner", function() {
                    expect(this.dialog.$(".import_data_grid").isLoading()).toBeFalsy();
                });
                it("display the correct tableName name", function() {
                    expect(this.dialog.$("input[name=tableName]").val()).toBe("new_test_name");
                });

                it("display the correct elements", function() {
                    expect(this.dialog.$("input[name='pattern']").val()).toBe("*.csv");
                    expect(this.dialog.$("input#pattern:checked")).toBeTruthy();
                    expect(this.dialog.$(".column_name input").eq(0).val()).toBe("column_1");
                });

                it("uses the custom styleSelect", function() {
                    expect(chorus.styleSelect).toHaveBeenCalled();
                });

                it("sets the csv contents to the model contents", function() {
                    expect(this.dialog.contents).toEqual(this.dialog.model.get("contents"));
                });
            });
        });

        context("clicking submit", function() {
            context("with invalid values", function() {
                beforeEach(function() {
                    this.dialog.$(".directions input:text").attr('value', "");
                    this.dialog.$("button.submit").click();
                });

                it("marks the table name as having an error", function() {
                    expect(this.dialog.$(".directions input:text")).toHaveClass("has_error");
                });
            });

            context("with an invalid file name pattern", function() {
                it("succeeds when the pathType pattern is not checked even if no match", function() {
                    this.dialog.$("input[name='pattern']").val(".*.txt");
                    this.dialog.$("button.submit").click();
                    expect(this.dialog.$("input[name='pattern']")).not.toHaveClass("has_error");
                });

                it("fails validation when the current sample does not match the pattern", function() {
                    this.dialog.$("input#directory").removeAttr('checked');
                    this.dialog.$("input#pattern").attr('checked', 'checked').change();
                    this.dialog.$("input[name='pattern']").val(".*.txt");
                    this.dialog.$("button.submit").click();
                    expect(this.dialog.$("input[name='pattern']")).toHaveClass("has_error");
                });

                it("fails validation when the current sample does match the pattern", function() {

                    this.dialog.$("input[name='pattern']").val("*.csv");
                    this.dialog.$("button.submit").click();
                    expect(this.dialog.$("input[name='pattern']")).not.toHaveClass("has_error");
                });
            });

            context("when importing an entire directory", function() {
                beforeEach(function() {
                    this.dialog.$("input#directory").attr('checked', 'checked');
                    this.dialog.$('button.submit').click();
                });

                it("starts the loading spinner", function() {
                    expect(this.dialog.$("button.submit").isLoading()).toBeTruthy();
                    expect(this.dialog.$("button.submit")).toContainTranslation("hdfs.create_external.creating");
                });

                it("posts to the right URL", function() {
                    var request = this.server.lastCreate();
                    expect(request.url).toMatchUrl("/workspaces/22/external_tables");
                    var json = request.json()['hdfs_external_table'];
                    expect(json['file_pattern']).toBe("*");
                    expect(json['hdfs_data_source_id']).toBe("234");
                    expect(json['column_names'][0]).toEqual('"column_1"');
                    expect(json['column_names'][1]).toEqual('"column_2"');
                    expect(json['path_type']).toBe('directory');
                    expect(json['hdfs_entry_id']).toBe('1');
                });

                context("when the post to import responds with success", function() {
                    beforeEach(function() {
                        spyOn(this.dialog, "closeModal");
                        spyOn(chorus, 'toast');
                        spyOn(chorus.PageEvents, 'trigger');
                        this.server.lastCreate().succeed();
                    });

                    it("closes the dialog and displays the right toast", function() {
                        expect(this.dialog.closeModal).toHaveBeenCalled();
                        expect(chorus.toast).toHaveBeenCalledWith("hdfs.create_external.success", {tableName: this.dialog.$("input:text").eq(0).val(), workspaceName: "workspace1"});
                    });

                    it("triggers csv_import:started", function() {
                        expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("csv_import:started");
                    });
                });
            });

            context("when importing only files that match a pattern", function() {
                beforeEach(function() {
                    this.dialog.$("input#directory").removeAttr('checked');
                    this.dialog.$("input#pattern").attr('checked', 'checked').change();
                    this.dialog.$("input[name='pattern']").val("*.csv");
                    this.dialog.$('button.submit').click();
                });

                it("posts to the right URL", function() {
                    var request = this.server.lastCreate();

                    expect(request.url).toMatchUrl("/workspaces/22/external_tables");
                    expect(request.json()['hdfs_external_table']['path_type']).toBe('pattern');
                    expect(request.json()['hdfs_external_table']['file_pattern']).toBe("*.csv");
                });
            });

            context("when the server responds with errors", function() {
                beforeEach(function() {
                    this.$type = this.dialog.$(".type").eq(1);
                    this.$type.find(".chosen").click();
                    this.$type.find(".popup_filter li").eq(3).find("a").click();
                    this.dialog.$("input[name=tableName]").val("testisgreat").change();
                    this.dialog.$(".column_name input").eq(0).val("gobbledigook").change();
                    this.dialog.$("button.submit").click();

                    this.server.lastCreate().failUnprocessableEntity();
                    this.dialog.model.serverErrors = [{message: "I like Cheese"}];
                });

                it("has no validation errors", function() {
                    expect(this.dialog.$(".has_error").length).toBe(0);
                });

                it("retains column names", function() {
                    expect(this.dialog.$(".column_name input").eq(0).val()).toBe("gobbledigook");
                });

                it("retains the table name", function() {
                    expect(this.dialog.$("input[name=tableName]").val()).toBe("testisgreat");
                });

                it("retains the data types", function() {
                    this.$type = this.dialog.$(".type").eq(1);
                    expect(this.$type.find(".chosen")).toHaveText("date");
                    expect(this.$type).toHaveClass("date");
                });
            });
        });
    });

    describe("select styling", function() {
        it("uses custom styled select box", function() {
            spyOn(chorus, 'styleSelect');
            $(document).trigger("reveal.facebox");
            expect(chorus.styleSelect).toHaveBeenCalled();
        });
    });

    describe("the help text tooltip", function() {
        beforeEach(function() {
            spyOn($.fn, 'qtip');
            this.dialog.render();
            this.qtipCall = $.fn.qtip.lastCall();
        });

        it("makes a tooltip for each help", function() {
            expect($.fn.qtip).toHaveBeenCalled();
            expect(this.qtipCall.object).toBe(".help");
        });

        it("renders a help text", function() {
            expect(this.qtipCall.args[0].content).toMatchTranslation("hdfs_data_source.create_external.specify_pattern_help_text");
        });
    });
});
