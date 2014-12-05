describe("chorus.models.tag", function() {
    beforeEach(function(){
        this.tag = new chorus.models.Tag({name: 'foo'});
    });

    describe('#matches', function(){
        it("compares tag names ignoring case", function() {
            expect(this.tag.matches('foo')).toBe(true);
            expect(this.tag.matches('FOO')).toBe(true);
            expect(this.tag.matches('baz')).toBe(false);
        });

        it('compares tags ignoring leading/trailing spaces', function(){
            expect(this.tag.matches(' foo ')).toBe(true);
        });
    });

    describe("#showUrlTemplate", function() {
        it("shows the URL for the tag", function() {
            expect(this.tag.showUrl()).toBe("#/tags/" + this.tag.name());
        });

        describe("when a workspaceId is provided", function() {
            it("shows the URL for the tag scoped to the workspace", function() {
                expect(this.tag.showUrl(123)).toBe("#/workspaces/123/tags/" + this.tag.name());
            });
        });

        describe("when the tag name has special characters", function() {
            beforeEach(function() {
                this.tag.set({ name: '!@#$%^&*()"'});
            });

            it('uri encodes the url', function() {
                expect(this.tag.showUrl()).toEqual('#/tags/!@%23$%25%5E&*()%22');
            });
        });
    });

    describe("validation", function() {
        context("when the name is empty", function() {
            beforeEach(function() {
                this.tag.set({name: ""});
            });

            it("must have a non-zero length name", function() {
                expect(this.tag.save(this.tag.attributes)).toBeFalsy();
            });

            it("save adds an error on the name attribute", function() {
                this.tag.save(this.tag.attributes);
                expect(this.tag.errors.name).toMatchTranslation("field_error.BLANK", {field: t("tag.name")});
            });
        });

        context("when the name length is greater than 100", function() {
            beforeEach(function() {
                this.tag.set({name: _.repeat("a", 101)});
            });

            it("save returns false", function() {
                expect(this.tag.save(this.tag.attributes)).toBeFalsy();
            });

            it("save adds an error on the name attribute", function() {
                this.tag.save(this.tag.attributes);
                expect(this.tag.errors.name).toMatchTranslation("field_error.TOO_LONG", {field: t("tag.name"), count: 100});
            });
        });
    });
});