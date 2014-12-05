describe("chorus.utilities.mime", function() {
    function verifyMime(ext, mime) {
        expect(chorus.utilities.mime(ext)).toBe(mime);
    }
    
    it("returns mime types suitable for codemirror given file extensions", function () {
        verifyMime("sql", "text/x-plsql");
        verifyMime("rb", "text/x-ruby");
        verifyMime("py", "text/x-python");
        verifyMime("r", "text/x-rsrc");
        verifyMime("pig", "text/x-pig");
        verifyMime("js", "javascript");
        verifyMime("md", "text/x-markdown");

        verifyMime("other", "text/plain");
        verifyMime("", "text/plain");
    });
});
