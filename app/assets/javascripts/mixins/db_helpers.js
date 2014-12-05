chorus.Mixins.dbHelpers = {
    ensureDoubleQuoted: function() {
        function encode(name) {
            var doubleQuoted = name.match(chorus.ValidationRegexes.DoubleQuoted());
            return doubleQuoted ? name : '"' + name + '"';
        }

        return _.map(arguments, function(arg) {
            return encode(arg);
        }).join('.');
    },

    sqlEscapeString: function(string) {
        return string.replace(/'/g, "''");
    }
};
