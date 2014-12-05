describe('chorus.handlebarsHelpers.tableau', function() {
    describe("usedInTableau", function() {
        var contextObjectClass = chorus.models.Base.extend({});

        beforeEach(function () {
            this.contextObject = new contextObjectClass();
        });

        context("when the first arguments is an array", function () {
            beforeEach(function () {
                this.workbookList = [
                    backboneFixtures.tableauWorkbook({name: "foo", url: "foo.com"}).attributes,
                    backboneFixtures.tableauWorkbook({name: "bar", url: "bar.com"}).attributes
                ];
                this.result = Handlebars.helpers.usedInTableau(this.workbookList).toString();
            });

            it("includes the 'published to workbook' information", function () {
                var workbook = this.workbookList[0];
                expect($(this.result).find("a:eq(0)").attr("href")).toMatchUrl('foo.com');
                expect($(this.result).find("a:eq(0)")).toContainText(workbook.name);
                expect($(this.result).find("a:eq(0)")).toHaveAttr("title", workbook.name);
            });

            it("should open link in new window", function() {
                expect($(this.result).find("a")).toHaveAttr("target", "_blank");
            });

            it("should indicate there is 1 other workbook", function () {
                expect($(this.result)).toContainTranslation("tableau.other_workbooks", {count:1});
            });
        });
    });

    describe("fromTableau", function () {
        beforeEach(function () {
            this.workfile = backboneFixtures.workfile.tableau();
        });

        it("show the tableau information", function () {
            var $result = $('<div>' + Handlebars.helpers.fromTableau(this.workfile) + '</div>');
            expect($result.find('a.tableau')).toHaveHref(this.workfile.get('workbookUrl'));
            expect($result.find('a.tableau')).toHaveText(this.workfile.get('workbookUrl'));
            expect($result.find('span.tableau_icon')).toExist();
        });
    });
});
