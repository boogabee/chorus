describe('chorus.handlebarsHelpers.search', function() {
    describe("displaySearchMatch", function () {
        context("on plain JS objects", function () {
            it("uses the search result if present", function () {
                var attributes = { schemaName:'ddemo', highlightedAttributes:{schemaName:["d<em>demo</em>"]}};
                expect(Handlebars.helpers.displaySearchMatch.call(attributes, 'schemaName').toString()).toBe("d<em>demo</em>");
            });

            it("falls back to the attributes", function () {
                var attributes = { schemaName:'ddemo', highlightedAttributes:{anotherAttribute:["d<em>demo</em>"]}};
                expect(Handlebars.helpers.displaySearchMatch.call(attributes, 'schemaName').toString()).toBe('ddemo');
            });

            it("doesn't complain if the highlightedAttributes are missing", function () {
                var attributes = { schemaName:'ddemo'};
                expect(Handlebars.helpers.displaySearchMatch.call(attributes, 'schemaName').toString()).toBe('ddemo');
            });

            it("doesn't complain if highlighted value is not wrapped in an array", function () {
                var attributes = {highlightedAttributes:{content:"SELECT * FROM <em>test</em> AS a"}};
                expect(Handlebars.helpers.displaySearchMatch.call(attributes, 'content').toString()).toBe("SELECT * FROM <em>test</em> AS a");
            });

            it("doesn't html-escape safe fields", function () {
                var attributes = {content:"this <b>content</b> has <i>html</i>"};
                expect(Handlebars.helpers.displaySearchMatchFromSafeField.call(attributes, 'content').toString()).toBe("this <b>content</b> has <i>html</i>");
            });

            it("html-escapes unsafe fields", function () {
                var attributes = {content:"this <b>content</b> has <i>html</i>"};
                expect(Handlebars.helpers.displaySearchMatch.call(attributes, 'content').toString()).toBe("this &lt;b&gt;content&lt;/b&gt; has &lt;i&gt;html&lt;/i&gt;");
            });
        });

        context("on backbone models", function () {
            it("uses the search result if present", function () {
                var model = new chorus.models.Base({ schemaName:'ddemo', highlightedAttributes:{schemaName:["d<em>demo</em>"]}});
                expect(Handlebars.helpers.displaySearchMatch.call(model, 'schemaName').toString()).toBe("d<em>demo</em>");
            });

            it("falls back to the attributes", function () {
                var model = new chorus.models.Base({ schemaName:'ddemo', highlightedAttributes:{anotherAttribute:["d<em>demo</em>"]}});
                expect(Handlebars.helpers.displaySearchMatch.call(model, 'schemaName').toString()).toBe('ddemo');
            });

            it("doesn't complain if the highlightedAttributes are missing", function () {
                var model = new chorus.models.Base({ schemaName:'ddemo'});
                expect(Handlebars.helpers.displaySearchMatch.call(model, 'schemaName').toString()).toBe('ddemo');
            });

            it("doesn't complain if highlighted value is not wrapped in an array", function () {
                var model = new chorus.models.Base({highlightedAttributes:{content:"SELECT * FROM <em>test</em> AS a"}});
                expect(Handlebars.helpers.displaySearchMatch.call(model, 'content').toString()).toBe("SELECT * FROM <em>test</em> AS a");
            });
        });
    });

    describe("searchResultCommentTitle", function () {
        context("when the comment is an insight", function () {
            beforeEach(function () {
                this.comment = backboneFixtures.activity.noteOnWorkfileCreated({isInsight:true}).attributes;
            });

            it("returns the insight title", function () {
                expect(Handlebars.helpers.searchResultCommentTitle(this.comment)).toMatchTranslation("search.supporting_message_types.insight");
            });
        });

        context("when the comment is a comment", function () {
            beforeEach(function () {
                this.comment = backboneFixtures.activity.noteOnWorkfileCreated().attributes;
                this.comment.isComment = true;
            });

            it("returns the comment title", function () {
                expect(Handlebars.helpers.searchResultCommentTitle(this.comment)).toMatchTranslation("search.supporting_message_types.comment");
            });
        });

        context("when the comment nothing special", function () {
            beforeEach(function () {
                this.comment = backboneFixtures.commentJson();
            });

            it("returns the note title", function () {
                expect(Handlebars.helpers.searchResultCommentTitle(this.comment)).toMatchTranslation("search.supporting_message_types.note");
            });
        });

        context("when the comment has a subType", function() {
            beforeEach(function() {
                this.comment = backboneFixtures.activity.noteOnWorkfileCreated().attributes;
                this.comment.subType = "table_description";
            });

            it("returns the table title", function() {
                expect(Handlebars.helpers.searchResultCommentTitle(this.comment)).toMatchTranslation("search.supporting_message_types.table_description");
            });
        });
    });
});