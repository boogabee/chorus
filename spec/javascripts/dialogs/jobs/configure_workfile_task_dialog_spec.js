describe("chorus.dialogs.ConfigureWorkfileTask", function () {
    beforeEach(function () {
        this.job = backboneFixtures.job();
        this.magicFileName = "magic";
        this.workFlow = backboneFixtures.workfile.alpine();
        this.workspace = this.workFlow.workspace();
        this.workFlows = [this.workFlow, backboneFixtures.workfile.alpine({fileName: this.magicFileName})];

        this.workFlowSet = new chorus.collections.WorkfileSet(this.workFlows, {fileType: 'work_flow', workspaceId: this.workspace.id});
    });

    describe("when initialized without a model", function () {
        beforeEach(function () {
            this.dialog = new chorus.dialogs.ConfigureWorkfileTask({job: this.job, collection: this.workFlowSet});
            this.dialog.render();
        });

        describe('#render', function () {
            it("shows the correct title", function () {
                expect(this.dialog.$("h1")).toContainTranslation("create_job_task_dialog.add_title");
            });

            it("only fetches work flows", function () {
                var lastFetch = this.server.lastFetchFor(this.workFlowSet);
                expect(lastFetch.url).toHaveUrlPath('/workspaces/' + this.workFlowSet.models[0].workspace().id + '/workfiles');
                expect(lastFetch.url).toContainQueryParams({fileType: 'work_flow'});
            });

            context("when the collection fetch completes", function () {
                beforeEach(function () {
                    this.server.completeFetchAllFor(this.workFlowSet, this.workFlows);
                });

                it("shows the correct button name", function () {
                    expect(this.dialog.$("button.submit")).toContainTranslation("create_job_task_dialog.add");
                });

                it("doesn't have multiSelection", function () {
                    expect(this.dialog.multiSelection).toBeFalsy();
                });

                describe("selecting an item", function () {
                    it("should mark the item selected", function () {
                        this.dialog.$("ul li:eq(0)").click();
                        expect(this.dialog.$("ul li:eq(0)")).toHaveClass("selected");
                    });

                    it("enables the form", function () {
                        var submitButton = this.dialog.$("button.submit");
                        expect(submitButton).toBeDisabled();
                        this.dialog.$("ul li:eq(0)").click();
                        expect(submitButton).toBeEnabled();
                    });

                    describe("submitting the form", function () {
                        beforeEach(function () {
                            this.dialog.$("ul li:eq(0)").click();
                            this.dialog.$("button.submit").click();
                        });

                        it("posts to the correct url", function () {
                            var url = this.server.lastCreateFor(this.dialog.model).url;
                            expect(url).toBe(this.dialog.model.url());
                        });

                        it("submits the correct fields", function () {
                            var json = this.server.lastCreateFor(this.dialog.model).json()['job_task'];
                            expect(json['action']).toBe('run_work_flow');
                            expect(json['workfile_id']).toBe(this.workFlow.get('id'));
                        });

                        context("when the save succeeds", function () {
                            beforeEach(function () {
                                spyOn(this.dialog, "closeModal");
                                spyOn(chorus, "toast");
                                spyOn(this.dialog.job, 'trigger');
                                this.server.lastCreateFor(this.dialog.model).succeed();
                            });

                            it("closes the modal", function () {
                                expect(this.dialog.closeModal).toHaveBeenCalled();
                            });

                            it("should create a toast", function () {
                                expect(chorus.toast).toHaveBeenCalledWith(this.dialog.message);
                            });

                            it("invalidates the job", function () {
                                expect(this.dialog.job.trigger).toHaveBeenCalledWith('invalidated');
                            });
                        });
                    });
                });

                describe("search", function () {
                    it("shows the correct placeholder", function () {
                        expect(this.dialog.$("input.chorus_search").attr("placeholder")).toMatchTranslation("job_task.work_flow.search_placeholder");
                    });

                    it("shows the correct item count label", function () {
                        expect(this.dialog.$(".count")).toContainTranslation("entity.name.Workfile", { count: 2 });
                    });

                    it("sets up search correctly", function () {
                        spyOn(this.dialog.collection, 'search');
                        this.dialog.$("input.chorus_search").val(this.magicFileName).trigger("keyup");
                        expect(this.dialog.collection.search).toHaveBeenCalled();
                    });

                    context("when the search fetch completes", function () {
                        beforeEach(function () {
                            this.dialog.$("input.chorus_search").val(this.magicFileName).trigger("keyup");
                            this.server.completeFetchFor(this.dialog.collection, [this.workFlows[1]]);
                        });

                        it("updates the count", function () {
                            expect(this.dialog.$(".list_content_details .count")).toContainTranslation("entity.name.Workfile", {count: 1});
                        });
                    });
                });
            });
        });
    });

    describe("when initialized with a model", function () {
        beforeEach(function () {
            this.dialog = new chorus.dialogs.ConfigureWorkfileTask({model: this.job.tasks().at(0), collection: this.workFlowSet});
            this.dialog.render();
        });

        it("has an 'Edit Task' title and a 'Save' button", function () {
            expect(this.dialog.$('.dialog_header h1')).toContainTranslation("create_job_task_dialog.edit_title");
            expect(this.dialog.$('button.submit')).toContainTranslation('create_job_task_dialog.save');
        });

        context("when the collection fetch completes", function () {
            beforeEach(function () {
                this.server.completeFetchAllFor(this.workFlowSet, this.workFlows);
            });

            describe("submitting the form", function () {
                beforeEach(function () {
                    this.dialog.$("ul li:eq(0)").click();
                    this.dialog.$("button.submit").click();
                });

                it("posts to the correct url", function () {
                    var url = this.server.lastUpdateFor(this.dialog.model).url;
                    expect(url).toBe(this.dialog.model.url());
                });

                it("submits the correct fields", function () {
                    var json = this.server.lastUpdateFor(this.dialog.model).json()['job_task'];
                    expect(json['action']).toBe('run_work_flow');
                    expect(json['workfile_id']).toBe(this.workFlow.get('id'));
                });

                context("when the save succeeds", function () {
                    beforeEach(function () {
                        spyOn(this.dialog, "closeModal");
                        spyOn(chorus, "toast");
                        spyOn(this.dialog.job, 'trigger');
                        this.server.lastUpdateFor(this.dialog.model).succeed();
                    });

                    it("closes the modal", function () {
                        expect(this.dialog.closeModal).toHaveBeenCalled();
                    });

                    it("should create a toast", function () {
                        expect(chorus.toast).toHaveBeenCalledWith(this.dialog.message);
                    });

                    it("invalidates the job", function () {
                        expect(this.dialog.job.trigger).toHaveBeenCalledWith('invalidated');
                    });
                });
            });
        });
    });

    context("when looking for a sql workfile", function () {
        beforeEach(function () {
            this.sqlWorkfile = backboneFixtures.workfile.sql();
            this.workfiles = [this.sqlWorkfile];
            this.sqlWorkfileSet = new chorus.collections.WorkfileSet(this.workfiles, {fileType: 'sql', workspaceId: this.workspace.id});
            this.dialog = new chorus.dialogs.ConfigureWorkfileTask({job: this.job, collection: this.sqlWorkfileSet});
            this.dialog.render();
        });

        it("only fetches work flows", function () {
            var lastFetch = this.server.lastFetchFor(this.sqlWorkfileSet);
            expect(lastFetch.url).toHaveUrlPath('/workspaces/' + this.sqlWorkfileSet.models[0].workspace().id + '/workfiles');
            expect(lastFetch.url).toContainQueryParams({fileType: 'sql'});
        });

        context("when the collection fetch completes", function () {
            beforeEach(function () {
                this.server.completeFetchAllFor(this.sqlWorkfileSet, this.workfiles);
            });

            describe("selecting an item", function () {
                describe("submitting the form", function () {
                    beforeEach(function () {
                        this.dialog.$("ul li:eq(0)").click();
                        this.dialog.$("button.submit").click();
                    });

                    it("posts to the correct url", function () {
                        var url = this.server.lastCreateFor(this.dialog.model).url;
                        expect(url).toBe(this.dialog.model.url());
                    });

                    it("submits the correct fields", function () {
                        var json = this.server.lastCreateFor(this.dialog.model).json()['job_task'];
                        expect(json['action']).toBe('run_sql_workfile');
                        expect(json['workfile_id']).toBe(this.sqlWorkfile.get('id'));
                    });
                });
            });
        });
    });
});
