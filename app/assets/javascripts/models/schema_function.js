chorus.models.SchemaFunction = chorus.models.Base.extend({
    constructorName: "SchemaFunction",

    toText: function() {
        var functionArguments = this.getFunctionArguments();

        var schemaName = this.ensureDoubleQuoted(this.get("schemaName"));
        var functionName = this.ensureDoubleQuoted(this.get("name"));

        var result = schemaName + "." + functionName + '(';
        result = result + functionArguments.join(', ');
        result = result + ')';
        return result;
    },

    toHintText: function() {
        return this.get("returnType") + " " + this.get('name') + this.formattedArgumentList(true);
    },

    getFunctionArguments: function() {
        var argNames = this.get('argNames') || [];
        return _.map(this.get('argTypes'), function(argType, index) {
            var argName = argNames[index] || "arg" + (index + 1);
            return argType + ' ' + argName;
        });
    },

    formattedArgumentList: function(ensureParams) {
        var args = this.getFunctionArguments();
        if (ensureParams || args.length > 0) {
            return "(" + args.join(", ") + ")";
        } else {
            return "";
        }
    }
});
