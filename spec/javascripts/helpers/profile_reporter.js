jasmine.ProfileReporter = {
    jasmineStarted: function() {
        this.timings = [];
    },

    jasmineDone: function() {
        _(this.timings).each(function(timing) {
            window.console.log(timing.spec.id + " - " + timing.spec.fullName + " : " + timing.elapsedMs + "ms\n");
        });
    },

    specStarted: function(spec) {
        this.timings.push({
            startTime: Date.now(),
            spec: spec
        });
    },

    specDone: function(spec) {
        if (this.timings.length > 0 && _(this.timings).last().spec.id === spec.id) {
            _(this.timings).last().endTime = Date.now();
            this.timings = _(this.timings).sortBy(function(timing){ timing.elapsedMs = timing.endTime - timing.startTime; return -timing.elapsedMs; }).slice(0, 10);
        }
    }
};

if (window.location.search.indexOf("profile=") !== -1) {
    jasmine.getEnv().addReporter(jasmine.ProfileReporter);
}
