function itGoesToThe404Page() {
    it("does go to the 404 page", function() {
        expect(Backbone.history.loadUrl).toHaveBeenCalledWith("/invalidRoute");
    });

    it("does not launch any dialog", function() {
        expect(this.modalSpy.lastModal()).not.toBeDefined();
    });
}

function itHandlesUpdatingInvalidCredentials() {
    context("and credentials are invalid", function() {
        beforeEach(function() {
            this.server.lastFetchFor(this.resource).failForbidden(this.errorJson.errors);
        });

        it("does not go to the 403 page", function() {
            expect(Backbone.history.loadUrl).not.toHaveBeenCalled();
        });

        it("launches the 'update credentials' dialog, and reloads after the credentials have been added", function() {
            var dialog = this.modalSpy.lastModal();
            expect(dialog).toBeA(chorus.dialogs.DataSourceAccount);
            expect(dialog.options.dataSource.id).toEqual(this.errorJson.errors.model_data.id);
            expect(dialog.options.title).toMatchTranslation("data_sources.account.update.title");
        });

        it("configure the dialog to reload after credentials are added and navigate back on dismissal", function() {
            var dialog = this.modalSpy.lastModal();
            expect(dialog.options.reload).toBeTruthy();
            expect(dialog.options.goBack).toBeTruthy();
        });
    });
}

function itHandlesAddingMissingCredentials() {
    context("when credentials are missing", function() {
        beforeEach(function() {
            delete this.errorJson.errors.record;
            this.server.lastFetchFor(this.resource).failForbidden(this.errorJson.errors);
        });

        it("does not go to the 403 page", function() {
            expect(Backbone.history.loadUrl).not.toHaveBeenCalled();
        });

        it("launches the 'add credentials' dialog, and reloads after the credentials have been added", function() {
            var dialog = this.modalSpy.lastModal();
            expect(dialog).toBeA(chorus.dialogs.DataSourceAccount);
            expect(dialog.options.dataSource.id).toEqual(this.errorJson.errors.model_data.id);

            expect(dialog.options.title).toMatchTranslation("data_sources.account.add.title");
        });

        it("configure the dialog to reload after credentials are added and navigate back on dismissal", function() {
            var dialog = this.modalSpy.lastModal();
            expect(dialog.options.reload).toBeTruthy();
            expect(dialog.options.goBack).toBeTruthy();
        });
    });
}

describe("chorus.Mixins.DataSourceCredentials", function() {
    describe("model", function() {
        beforeEach(function() {
            this.collection = new chorus.collections.Base();
            spyOn(this.collection, "url").andReturn("some/url");
            _.extend(this.collection, chorus.Mixins.DataSourceCredentials.model);
        });

        describe("#dataSourceRequiringCredentials", function() {
            context('when a fetch failed because of missing data source credentials', function() {
                it("returns a data source model with the right id and attributes", function() {
                    var errorJson = backboneFixtures.invalidCredentialsErrorJson();

                    this.collection.fetch();
                    this.server.lastFetchFor(this.collection).respondJson(403, errorJson);
                    var expectedDataSourceType = chorus.models[chorus.models.DynamicDataSource.typeMap[errorJson.errors.model_data.entity_type]];

                    var dataSource = this.collection.dataSourceRequiringCredentials();
                    expect(dataSource).toBeA(expectedDataSourceType);
                    expect(dataSource.get("id")).toBe(errorJson.errors.model_data.id);
                    expect(dataSource.get("entityType")).toBe(errorJson.errors.model_data.entity_type);
                });
            });
        });
    });

    describe("page", function() {
        beforeEach(function() {
            this.resource = new (chorus.models.Base.extend(chorus.Mixins.DataSourceCredentials.model))();
            this.resource.urlTemplate = "foo";

            this.page = new (chorus.pages.Base.extend(chorus.Mixins.DataSourceCredentials.page))();
            this.page.handleFetchErrorsFor(this.resource);

            this.modalSpy = stubModals();
            spyOn(Backbone.history, 'loadUrl');

            this.resource.fetch();
        });

        context("for a dataSource with individual accounts", function() {
            beforeEach(function() {
                this.errorJson = backboneFixtures.invalidCredentialsErrorJson({errors: {model_data: {shared: false}}});
            });

            itHandlesAddingMissingCredentials();

            itHandlesUpdatingInvalidCredentials();
        });

        context("for a shared dataSource", function() {
            beforeEach(function() {
                this.errorJson = backboneFixtures.invalidCredentialsErrorJson({errors: {model_data: {shared: true}}});
            });

            context("when the user is an Admin", function() {
                beforeEach(function() {
                    chorus.session.user().set('admin', true);
                });
                itHandlesUpdatingInvalidCredentials();
            });

            context("when the user is the Owner", function() {
                beforeEach(function() {
                    this.errorJson = backboneFixtures.invalidCredentialsErrorJson(
                        {errors: { model_data: {owner_id: chorus.session.user().get('id') } } }
                    );
                });
                itHandlesUpdatingInvalidCredentials();
            });


            context("when the user is neither an Admin nor the Owner", function() {
                beforeEach(function() {
                    chorus.session.user().set('admin', false);
                    this.errorJson = backboneFixtures.invalidCredentialsErrorJson(
                        {errors: { model_data: {owner_id: 'some_nonsense', shared: true } } }
                    );
                });

                context("and credentials are invalid", function() {
                    beforeEach(function() {
                        this.server.lastFetchFor(this.resource).failForbidden(this.errorJson.errors);
                    });

                    it("does go to the 403 page", function() {
                        expect(Backbone.history.loadUrl).toHaveBeenCalledWith("/forbidden");
                    });

                    it("does not launch any dialog", function() {
                        expect(this.modalSpy.lastModal()).not.toBeDefined();
                    });

                    it("displays an appropriate explanation", function() {
                        expect(chorus.pageOptions.title).toMatchTranslation("data_sources.shared_account_invalid.title");
                        expect(chorus.pageOptions.text).toMatchTranslation("data_sources.shared_account_invalid.text");
                    });
                });
            });
        });



        context("fetch failed for some other reason", function() {
            beforeEach(function() {
                spyOn(this.resource, 'dataSourceRequiringCredentials').andReturn(undefined);
                this.server.lastFetchFor(this.resource).failNotFound();
            });

            itGoesToThe404Page();
        });

        context("when the resource does not respond to #dataSourceRequiringCredentials", function() {
            beforeEach(function() {
                this.otherModel = new (chorus.models.Base.extend({urlTemplate: "bar"}))();
                this.page.handleFetchErrorsFor(this.otherModel);
                this.otherModel.fetch();
                this.server.lastFetchFor(this.otherModel).failNotFound([ { message: "Not found" } ]);
            });

            itGoesToThe404Page();
        });
    });
});
