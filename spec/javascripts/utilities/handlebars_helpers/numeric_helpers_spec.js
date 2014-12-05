describe('chorus.handlebarsHelpers.numeric', function() {
    describe("percentage", function () {
        beforeEach(function () {
            this.template = "{{percentage value}}";
        });

        it("should display the value rounded to two decimal places", function () {
            var context = {value:10.494727};
            var string = Handlebars.compile(this.template)(context);
            expect(string).toBe("10.49%");
        });
    });

    describe("percentageFromFraction", function () {
        beforeEach(function () {
            this.template = "{{percentageFromFraction value}}";
        });

        it("should convert the value to a percentage rounded to two decimal places", function () {
            var context = {value:0.10494727};
            var string = Handlebars.compile(this.template)(context);
            expect(string).toBe("10.49%");
        });
    });

    describe("round", function () {
        beforeEach(function () {
            this.template = "{{round value}}";
        });

        it("should not round the value", function () {
            var context = {value:0.0012344};
            var string = Handlebars.compile(this.template)(context);
            expect(string.toString()).toContainText("0.0012344");
        });

        it("should round the value to two decimal places", function () {
            var context = {value:10.494727};
            var string = Handlebars.compile(this.template)(context);
            expect(string.toString()).toContainText("10.49");
        });
    });
});
