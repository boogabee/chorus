chorus.handlebarsHelpers.time = {
    displayAbbreviatedTimestamp: function(timestamp) {
        var date = chorus.parseDateFromApi(timestamp);
        return date ? date.toString("MMMM d") : "";
    },

    relativeTimestamp: function(timestamp) {
        var date = chorus.parseDateFromApi(timestamp);
        return date ? date.toRelativeTime(60000) : "";
    },

    displayTimestamp: function (timestamp) {
        var date = moment(timestamp);
        return (timestamp && date.isValid()) ? date.format('MMMM Do YYYY, h:mm a') : "";
    },

    displayDuration: function (finished, started) {
        var f = moment(finished);
        var s = moment(started);
        var duration = "";
        if (finished && f.isValid() && started && s.isValid()) {
            var d = moment.duration(f-s);
            duration = _.pad(d.hours(), 2, '0') + ":" + _.pad(d.minutes(), 2, '0') + ":" + _.pad(d.seconds(), 2, '0');
        }
        return duration;
    }
};

_.each(chorus.handlebarsHelpers.time, function(helper, name) {
    Handlebars.registerHelper(name, helper);
});