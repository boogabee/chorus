describe("chorus.models.SchemaImport", function() {
    beforeEach(function() {
        this.model = new chorus.models.SchemaImport({
            id: '1',
            datasetId: '12',
            schemaId: '34'
        });
    });

    describe('url', function() {
        it('saves to the schema/:id/imports', function() {
            expect(this.model.url()).toHaveUrlPath('/schemas/34/imports');
        });
    });

    describe("validations", function() {
        context("when creating a new table", function() {
            beforeEach(function() {
                this.attrs = {
                    toTable: "Foo",
                    sampleCount: "23",
                    truncate: "true",
                    newTable: "true"
                };
            });

            _.each(["toTable", "truncate", "newTable"], function(attr) {
                it("should require " + attr, function() {
                    this.attrs[attr] = "";
                    expect(this.model.performValidation(this.attrs)).toBeFalsy();
                });
            });

            context("with a conforming toTable name", function() {
                it("validates", function() {
                    expect(this.model.performValidation(this.attrs)).toBeTruthy();
                });
            });

            context("with a non-conforming toTable name", function() {
                beforeEach(function() {
                    this.attrs.toTable = "__foo";
                });

                it("fails validations", function() {
                    expect(this.model.performValidation(this.attrs)).toBeFalsy();
                });
            });

            context("when useLimitRows is enabled", function() {
                beforeEach(function() {
                    this.attrs.useLimitRows = true;
                });

                it("should only allow digits for the row limit", function() {
                    this.attrs.sampleCount = "a3v4s5";
                    expect(this.model.performValidation(this.attrs)).toBeFalsy();
                });
            });

            context("when useLimitRows is not enabled", function() {
                beforeEach(function() {
                    this.attrs.useLimitRows = false;
                });

                it("should not validate the sampleCount field", function() {
                    this.attrs.sampleCount = "";
                    expect(this.model.performValidation(this.attrs)).toBeTruthy();
                });
            });
        });
    });
});
