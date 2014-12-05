chorus.handlebarsHelpers.numeric = {
    percentage: function(value) {
        var number = Math.pow(10, 2);
        var result = Math.round(value * number) / number;
        return result + "%";
    },

    percentageFromFraction: function(fraction) {
        return Handlebars.helpers.percentage(fraction * 100);
    },

    round: function(value) {
        if (value > 0.1) {
            var number = Math.pow(10, 2);
            return Math.round(value * number) / number;
        }

        return value;
    }
};

_.each(chorus.handlebarsHelpers.numeric, function(helper, name) {
    Handlebars.registerHelper(name, helper);
});
