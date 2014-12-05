Handlebars.registerHelper("t", function(key) {
    var args = arguments;
    if(args[args.length - 1].hash) {
        args[args.length - 1] = args[args.length - 1].hash;
    }
    return t.apply(this, args);
});