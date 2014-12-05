describe("chorus.models.Sandbox", function() {
    function expectValid(attrs, model) {
        model.performValidation(attrs);
        expect(model.isValid()).toBeTruthy();
    }

    function expectInvalid(attrs, model, invalid_attrs) {
        invalid_attrs || (invalid_attrs = []);
        model.performValidation(attrs);
        expect(model.isValid()).toBeFalsy();
        _.each(invalid_attrs, function(invalid_attr) {
            expect(model.errors);
        });
    }

    beforeEach(function() {
        this.model = backboneFixtures.workspace().sandbox();
    });

    describe("#url", function() {
        it("has the right url", function() {
            expect(this.model.url()).toHaveUrlPath("/workspaces/" + this.model.get('workspaceId') + "/sandbox");
        });
    });

    describe("#schema", function() {
        beforeEach(function() {
            this.schema = this.model.schema();
        });

        it('should be created with data source, database, and schema names and ids', function() {
            expect(this.schema.get('id')).toBe(this.model.get('id'));
            expect(this.schema.get('name')).toBe(this.model.get('name'));
        });

        it("should memoize the schema", function() {
            expect(this.schema).toBe(this.model.schema());
        });
    });

    describe("#database", function() {
        beforeEach(function() {
            this.database = this.model.database();
        });

        it("returns a database with the right id and dataSourceId", function() {
            expect(this.database).toBeA(chorus.models.Database);
            expect(this.database.get("id")).toBe(this.model.get("database").id);
            expect(this.database.get("name")).toBe(this.model.get("database").name);
        });

        it("memoizes", function() {
            expect(this.database).toBe(this.model.database());
        });
    });

    describe("#dataSource", function() {
        beforeEach(function() {
            this.dataSource = this.model.dataSource();
        });

        it('returns a data source with the right id and name', function() {
            expect(this.dataSource).toBeA(chorus.models.GpdbDataSource);
            expect(this.dataSource.get("id")).toBe(this.model.get("database").dataSource.id);
            expect(this.dataSource.get("name")).toBe(this.model.get("database").dataSource.name);
        });

        it("memoizes", function() {
            expect(this.dataSource).toBe(this.model.dataSource());
        });
    });

    describe("validations", function() {
        beforeEach(function() {
            this.model.set({
                dataSourceId: '1',
                databaseId: '2',
                schemaId: '3'
            });
            expectValid({}, this.model);
        });

        context("with a database id", function() {
            beforeEach(function() {
                this.model.set('databaseId', 1);
            });

            context("without a schema", function() {
                beforeEach(function() {
                    this.model.unset("schemaId");
                    this.model.unset("schemaName");
                });

                it("requires a schema name", function() {
                    expectInvalid({ }, this.model, [ "schemaName" ]);
                    expect(this.model.errors["schemaName"]).toMatchTranslation("validation.required", { fieldName : this.model._textForAttr("schemaName") });
                });

                it("requires that the schema name not start with a number", function() {
                    expectInvalid({ schemaName: "3friends_of_the_forest" }, this.model, [ "schemaName" ]);
                    expectValid({ schemaName: "friends_of_the_forest" }, this.model);
                });

                it("requires that the schema name does NOT contain whitespace", function() {
                    expectInvalid({ schemaName: "friends of the forest" }, this.model, [ "schemaName" ]);
                });
            });
        });

        context("without a database id", function() {
            beforeEach(function() {
                this.model.set({ databaseName: "bernards_db", schemaName: "cool_schema" });
                this.model.unset('databaseId');
                expectValid({}, this.model);
            });

            it("requires a database name", function() {
                this.model.unset("databaseName");
                expectInvalid({ }, this.model, [ "databaseName" ]);
                expect(this.model.errors["databaseName"]).toMatchTranslation("validation.required", { fieldName : this.model._textForAttr("databaseName") });
            });

            it("requires that the database name not start with a number", function() {
                expectInvalid({ databaseName: "3friends_of_the_forest" }, this.model, [ "databaseName" ]);
            });

            it("requires that the database name does NOT contain whitespace", function() {
                expectInvalid({ databaseName: "friends of the forest" }, this.model, [ "databaseName" ]);
            });

            it("requires a schema name", function() {
                this.model.unset("schemaName");
                expectInvalid({ }, this.model, [ "schemaName" ]);
                expect(this.model.errors["schemaName"]).toMatchTranslation("validation.required", { fieldName : this.model._textForAttr("schemaName") });
            });

            context("when a schema name is specified", function() {
                it("requires that the name not start with a number", function() {
                    expectInvalid({ schemaName: "3friends_of_the_forest" }, this.model, [ "schemaName" ]);
                });

                it("requires that the name does NOT contain whitespace", function() {
                    expectInvalid({ schemaName: "friends of the forest" }, this.model, [ "schemaName" ]);
                });
            });
        });
    });
});
