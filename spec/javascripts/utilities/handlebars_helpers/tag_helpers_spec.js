describe('chorus.handlebarsHelpers.tag', function() {
    describe("displayTagMatch", function () {
        var searchResultContext = {
            highlightedAttributes: {
                tagNames: []
            }
        };

        context("when the tag does not have special characters", function() {
            it("returns the same tag name if there is no match", function() {
                expect(Handlebars.helpers.displayTagMatch(searchResultContext, "cloud")).toEqual(
                    new Handlebars.SafeString("cloud"));
            });

            it("returns the highlighted tag if there is a match", function(){
                searchResultContext.highlightedAttributes.tagNames = ["<em>cloud</em>"];

                expect(Handlebars.helpers.displayTagMatch(searchResultContext, "cloud")).toEqual(
                    new Handlebars.SafeString("<em>cloud</em>"));
            });

            it("returns a partially highlighted tag if there is a partial match", function(){
                searchResultContext.highlightedAttributes.tagNames = ["<em>clo</em>ud"];

                expect(Handlebars.helpers.displayTagMatch(searchResultContext, "cloud")).toEqual(
                    new Handlebars.SafeString("<em>clo</em>ud"));
            });
        });

        context("when the tag has special characters", function() {
            var tagName = '<script>alert("security vulnerability!")</script>';

            it("returns an html encoded string when there is no match", function(){
                var escapedString = '&lt;script&gt;alert(&quot;security vulnerability!&quot;)&lt;/script&gt;';
                searchResultContext.highlightedAttributes.tagNames = [];

                expect(Handlebars.helpers.displayTagMatch(searchResultContext, tagName)).toEqual(
                    new Handlebars.SafeString(escapedString));
            });
        });
    });

    describe("escapeAllowingHtmlTag", function() {
        var originalString;
        var escapeAllowingHtmlTag;
        beforeEach(function() {
            escapeAllowingHtmlTag = Handlebars.helpers.escapeAllowingHtmlTag;
            originalString = '<script>alert("<em>security</em> vulnerability!")</script>';
        });

        it("returns a safe string with the all tags escaped except specified tag", function() {
            expect(escapeAllowingHtmlTag(originalString, "em")).toEqual(
                new Handlebars.SafeString('&lt;script&gt;alert(&quot;<em>security</em> vulnerability!&quot;)&lt;/script&gt;')
            );
        });
    });
});