jasmine.MAX_PRETTY_PRINT_DEPTH = 5;

chorus.useFakeTimers = function() {
    var clock = sinon.useFakeTimers.apply(sinon, arguments);
    window.afterSpecFunctions.push(function() {clock.restore();});
    return clock;
};