describe('chorus.handlebarsHelpers.link', function() {
    describe("moreLink", function () {
        describe("when the collection has more than max elements", function () {
            it("returns markup", function () {
                var el = $("<div>" + Handlebars.helpers.moreLink([1, 2, 3, 4], 3, "activity.comments.more", "activity.comments.less") + "</div>");
                expect(el.find(".morelinks a.more")).toExist();
                expect(el.find(".morelinks a.less")).toExist();
                expect(el.find(".morelinks a.more")).toHaveText(t("activity.comments.more", {count:1}));
                expect(el.find(".morelinks a.less")).toHaveText(t("activity.comments.less"));
            });
        });

        describe("when the collection has less than max + 1 elements", function () {
            it("returns no markup", function () {
                var el = $("<div>" + Handlebars.helpers.moreLink([1, 2, 3, 4], 3, "thing", "less") + "</div>");
                expect(el.find(".links")).not.toExist();
            });
        });
    });

    describe("eachWithMoreLink", function () {
        beforeEach(function () {
            this.yieldSpy = {
                fn: jasmine.createSpy(),
                inverse: jasmine.createSpy()
            };
            spyOn(Handlebars.helpers, "moreLink");
        });

        describe("when the collection has more than max elements", function () {
            beforeEach(function () {
                this.collection = [
                    { name:"foo" },
                    { name:"bar" },
                    { name:"bro" }
                ];

                Handlebars.helpers.eachWithMoreLink(this.collection, 2, "activity.comments.more",
                    "activity.comments.less", false, this.yieldSpy);
            });

            it("yields to the block for each element", function () {
                expect(this.yieldSpy.fn.calls.count()).toBe(3);
            });

            it("calls moreLink", function () {
                expect(Handlebars.helpers.moreLink).toHaveBeenCalledWith(this.collection, 2,
                    "activity.comments.more", "activity.comments.less");
            });

            it("sets the 'more' context attribute when yielding for each element with an index greater than max", function () {
                expect(this.yieldSpy.fn.nthCall(0).args[0].moreClass).toBe("");
                expect(this.yieldSpy.fn.nthCall(1).args[0].moreClass).toBe("");
                expect(this.yieldSpy.fn.nthCall(2).args[0].moreClass).toBe("more");
            });
        });

        describe("when showLast is true", function () {
            beforeEach(function () {
                this.collection = [
                    { name:"foo" },
                    { name:"bar" },
                    { name:"bro" }
                ];

                Handlebars.helpers.eachWithMoreLink(this.collection, 2, "activity_stream.comments.more",
                    "activity_stream.comments.less", true, this.yieldSpy);
            });

            it("sets the 'more' context attribute when yielding for each element with an index less than length - max", function () {
                expect(this.yieldSpy.fn.nthCall(0).args[0].moreClass).toBe("more");
                expect(this.yieldSpy.fn.nthCall(1).args[0].moreClass).toBe("");
                expect(this.yieldSpy.fn.nthCall(2).args[0].moreClass).toBe("");
            });
        });

        describe("when the collection has less than or equal to max elements", function () {
            beforeEach(function () {
                this.collection = [
                    { name:"foo" },
                    { name:"bar" }
                ];

                Handlebars.helpers.eachWithMoreLink(this.collection, 2, "activity.comments.more",
                    "activity.comments.less", true, this.yieldSpy);
            });

            it("yields to the block for each element", function () {
                expect(this.yieldSpy.fn.calls.count()).toBe(2);
            });

            it("calls moreLink", function () {
                expect(Handlebars.helpers.moreLink).toHaveBeenCalledWith(this.collection, 2,
                    "activity.comments.more", "activity.comments.less");
            });

            it("does not set the 'more' context attribute when yielding for any element", function () {
                expect(this.yieldSpy.fn.nthCall(0).args[0].moreClass).toBe("");
                expect(this.yieldSpy.fn.nthCall(1).args[0].moreClass).toBe("");
            });
        });
    });

    describe("fileIconUrl", function () {
        it("returns the icon url for the file", function () {
            expect(Handlebars.helpers.fileIconUrl("SQL", "medium")).toBe(chorus.urlHelpers.fileIconUrl("SQL", "medium"));
        });
    });

    describe("linkTo", function () {
        it("returns an html string with the right text and href", function () {
            var link = $(Handlebars.helpers.linkTo("/users/1", "Charlie").toString());

            // Coding like weirdos here to make IE8 happy
            expect(link.is("a")).toBeTruthy();
            expect(link.text().trim()).toBe("Charlie");
            expect(link.attr("href")).toBe("/users/1");
        });

        it("applies the given attributes", function () {
            var link = Handlebars.helpers.linkTo("/users/1", "Charlie", { 'class':"dude" }).toString();
            expect($(link).hasClass("dude")).toBeTruthy();
        });

        it("html escapes the text", function () {
            var unsafeString = "<em>stuff</em>";
            var link = Handlebars.helpers.linkTo("/", unsafeString).toString();
            expect(link).toMatch('&lt;em&gt;');
        });

        it("does not html escape the text if it has been declared safe", function () {
            var safeString = new Handlebars.SafeString("<em>stuff</em>");
            var link = Handlebars.helpers.linkTo("/", safeString).toString();
            expect(link).toMatch('<em>');
        });
    });
});
