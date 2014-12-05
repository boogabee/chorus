describe("chorus.views.SearchResults", function() {
    var makeSearchResults = function() {
        var result = backboneFixtures.searchResult();
        var attributeKeys = _.keys(result.attributes);
        _.each(attributeKeys, function (attribute) {
            if (attribute === 'completeJson') { return; }
            if (attribute === 'dataSources') { return; }
            if (attribute === 'dataSets') { return; }

            var value = result.get(attribute);
            value.numFound = Math.min(value.results.length, 2);
            value.results = value.results.splice(0, 2);
        });

        result.set({
            entityType: "all",
            workspaceId: '10001'
        });
        return result;
    };

    context("when there are no search results", function() {
        beforeEach(function() {
            this.model = backboneFixtures.emptySearchResult();
            this.model.set({ query: "foo" });
            this.view = new chorus.views.SearchResults({model: this.model});
            this.view.render();
        });

        it("displays the blank slate text", function() {
            expect(this.view.$(".sorry .header").text()).toContain(t("search.no_results.header"));
            expect(this.view.$(".sorry ul li").text()).toContain(t("search.no_results.check_spelling"));
            expect(this.view.$(".sorry ul li").text()).toContain(t("search.no_results.try_wildcards"));
        });

        context("and there are no filters applied", function() {
            beforeEach(function() {
                spyOn(this.model, "isConstrained").andReturn(false);
                this.view = new chorus.views.SearchResults({model: this.model});
                this.view.render();
            });

            it("does not suggest expanding the search", function() {
                expect(this.view.$(".sorry ul li").text()).not.toContain(t("search.no_results.expand"));
            });
        });

        context("and there are filters applied", function() {
            beforeEach(function() {
                spyOn(this.model, "isConstrained").andReturn(true);
                this.view = new chorus.views.SearchResults({model: this.model});
                this.view.render();
            });

            it("suggests expanding the search", function() {
                expect(this.view.$(".sorry ul li").text()).toContain(t("search.no_results.expand"));
                expect(this.view.$(".sorry ul li a")).toHaveHref("#/search/foo");
            });
        });
    });

    context("when there are search results", function() {
        beforeEach(function() {
            this.model = makeSearchResults();
            this.view = new chorus.views.SearchResults({model: this.model});
            this.view.render();
        });

        context("when searching for all types of items", function() {
            it("includes a section for every type of item", function() {
                var sections = this.view.$(".search_result_list ul");
                expect(sections.filter(".user_list.selectable")).toExist();
                expect(sections.filter(".workfile_list.selectable")).toExist();
                expect(sections.filter(".attachment_list.selectable")).toExist();
                expect(sections.filter(".workspace_list.selectable")).toExist();
                expect(sections.filter(".hdfs_entry_list.selectable")).toExist();
                expect(sections.filter(".data_source_list.selectable")).toExist();
            });
        });

        context("when searching for only workfiles", function() {
            function itShowsOnlyTheWorkfileSection() {
                it("shows the workfile section", function() {
                    expect(this.view.$(".search_result_list .workfile_list")).toExist();
                });

                it("does not show the sections for other types of items", function() {
                    expect(this.view.$(".search_result_list .this_workspace")).not.toExist();
                    expect(this.view.$(".search_result_list .attachment_list")).not.toExist();
                    expect(this.view.$(".search_result_list .data_source_list")).not.toExist();
                    expect(this.view.$(".search_result_list .workspace_list")).not.toExist();
                    expect(this.view.$(".search_result_list .user_list")).not.toExist();
                    expect(this.view.$(".search_result_list .dataset_list")).not.toExist();
                    expect(this.view.$(".search_result_list .hdfs_entry_list")).not.toExist();
                });
            }

            beforeEach(function() {
                this.model = makeSearchResults();
                this.model.set({ entityType: "workfile" });
                this.model.unset("workspaces");
                this.model.unset("otherFiles");
                this.model.unset("users");
                this.model.unset("hdfsEntries");
                this.model.unset("datasets");
                this.model.unset("dataSources");
                this.view = new chorus.views.SearchResults({ model: this.model });
                this.view.render();
            });

            itShowsOnlyTheWorkfileSection();
        });

        context("when searching for only workfiles in a particular workspace", function() {
            beforeEach(function() {
                this.model = backboneFixtures.searchResultInWorkspaceWithEntityTypeWorkfile();
                this.model.set({
                    entityType: "workfile",
                    workspaceId: "101",
                    searchIn: "this_workspace"
                });
                this.view = new chorus.views.SearchResults({ model: this.model });
                this.view.render();
            });

            it("includes a section for the workspace specific results", function() {
                expect(this.view.$(".search_result_list.this_workspace .selectable")).toExist();
            });

            it("does not show the other sections", function() {
                expect(this.view.$(".workfile_list")).toHaveHtml("");
                expect(this.view.$(".attachment_list")).toHaveHtml("");
                expect(this.view.$(".data_source_list")).toHaveHtml("");
                expect(this.view.$(".workspace_list")).toHaveHtml("");
                expect(this.view.$(".user_list")).toHaveHtml("");
                expect(this.view.$(".dataset_list")).toHaveHtml("");
                expect(this.view.$(".hdfs_list")).toHaveHtml("");
            });
        });

        describe("clicking an li", function() {
            beforeEach(function() {
                this.eventSpy = spyOn(chorus.PageEvents, 'trigger');
            });

            context("when the item was already selected", function() {
                it("doesn't trigger an event", function() {
                    var workfileToClick = this.model.workfiles().at(1);
                    this.view.$(".workfile_list li").eq(1).click();
                    this.eventSpy.reset();
                    this.view.$(".workfile_list li").eq(1).click();
                    expect(chorus.PageEvents.trigger).not.toHaveBeenCalledWith("workfile:selected", workfileToClick);
                });
            });

            context("when the li is in the 'this workspace' section", function() {
                var filter, item;

                beforeEach(function() {
                    this.model = backboneFixtures.searchResultInWorkspace();
                    this.model.set({
                        workspaceId: "101",
                        searchIn: "this_workspace"
                    });
                    this.view = new chorus.views.SearchResults({ model: this.model });
                    this.view.render();
                    
                    filter = function(type){
                        return function(item) {return item.get("entityType") === type; };
                    };

                    item = function(scope, type){
                        return scope.view.$(".this_workspace [data-template=search_"+type+"]");
                    };
                });

                it("triggers the 'workfile:selected' event on itself, with the clicked model, when a workfile is clicked", function() {
                    var modelToClick = this.model.workspaceItems().find(filter('workfile'));
                    item(this, 'workfile').click();
                    expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("workfile:selected", modelToClick);
                });

                it("triggers the 'dataset:selected' event on itself, with the clicked model, when a dataset is clicked", function() {
                    var modelToClick = this.model.workspaceItems().find(filter('dataset'));
                    item(this, 'dataset').click();
                    expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("dataset:selected", modelToClick);
                });
            });

            context("when the li is for a workfile", function() {
                it("triggers the 'workfile:selected' event on itself, with the clicked workfile", function() {
                    var workfileToClick = this.model.workfiles().at(1);
                    this.view.$(".workfile_list li").eq(1).click();
                    expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("workfile:selected", workfileToClick);
                });
            });

            context("when the li is for an attachment", function() {
                it("triggers the 'attachment:selected' event on itself, with the clicked attachment", function() {
                    var attachmentToClick = this.model.attachments().at(1);
                    this.view.$(".attachment_list li").eq(1).click();
                    expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("attachment:selected", attachmentToClick);
                });
            });

            context("when the li is for a workspace", function() {
                it("triggers the 'workspace:selected' page event, with the clicked workspace", function() {
                    var workspaceToClick = this.model.workspaces().at(1);
                    this.view.$(".workspace_list li").eq(1).click();
                    expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("workspace:selected", workspaceToClick);
                });
            });

            context("when the li is for a tabular data", function() {
                it("triggers the 'dataset:selected' page event, with the clicked tabular data", function() {
                    var modelToClick = this.model.datasets().at(0);
                    this.view.$(".dataset_list li").eq(0).click();
                    expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("dataset:selected", modelToClick);
                });
            });

            context("when the li is for a hadoop file", function() {
                it("triggers the 'hdfs_entry:selected' page event with the clicked hdfs file", function() {
                    var modelToClick = this.model.hdfs_entries().at(1);
                    this.view.$(".hdfs_list li").eq(1).click();
                    expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("hdfs_entry:selected", modelToClick);
                });
            });

            context('when the li is for a data source', function() {
                it("triggers the 'data_source:selected' page event with the clicked data source", function() {
                    var modelToClick = this.model.dataSources().find(function (dataSource) { return dataSource.isGreenplum(); });
                    this.view.$(".data_source_list .gpdb_data_source").eq(0).click();
                    expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("data_source:selected", modelToClick);
                });
            });

            context('when the li is for a hadoop data source', function() {
                it("triggers the 'data_source:selected' page event with the clicked data source", function() {
                    var modelToClick = this.model.dataSources().find(function (dataSource) { return dataSource.isHadoop(); });
                    this.view.$(".data_source_list .hdfs_data_source").eq(0).click();
                    expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("data_source:selected", modelToClick);
                });
            });

            context('when the li is for a gnip data source', function() {
                it("triggers the 'data_source:selected' page event with the clicked data source", function() {
                    var modelToClick = this.model.dataSources().find(function (dataSource) { return dataSource.isGnip(); });
                    this.view.$(".data_source_list .gnip_data_source").eq(0).click();
                    expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("data_source:selected", modelToClick);
                });
            });
        });

        describe("multiple selection", function() {
            it("starts with an empty set of selected models", function() {
                expect(this.view.selectedModels.length).toEqual(0);
            });

            it("clicking a checkbox adds the model to the selectedModels", function() {
                $('#jasmine_content').append(this.view.$el);
                var workfileToClick = this.model.workfiles().at(1);
                this.view.$(".workfile_list li input[type=checkbox]").eq(1).prop("checked", true).click();
                expect(_(this.view.selectedModels.models).pluck('id')).toEqual([workfileToClick.id]);
            });

            describe("when workspace specific items are found", function() {
                beforeEach(function() {
                    this.model = backboneFixtures.searchResultInWorkspace();
                    this.model.set({
                        workspaceId: "101",
                        searchIn: "this_workspace"
                    });
                    this.view = new chorus.views.SearchResults({ model: this.model });
                    this.view.render();
                });

                it("clicking a checkbox in the workspace specific section adds the model to the selectedModels", function() {
                    $('#jasmine_content').append(this.view.$el);
                    var itemToClick = this.model.workspaceItems().at(1);
                    this.view.$(".this_workspace li input[type=checkbox]").eq(1).click();
                    expect(this.view.selectedModels.models).toEqual([itemToClick]);
                });
            });
        });
    });
});
