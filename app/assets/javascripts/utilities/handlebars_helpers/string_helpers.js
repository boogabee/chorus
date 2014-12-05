chorus.handlebarsHelpers.string = {
    pluralize: function(numberOrArray, key, options) {
        var hash = options && options.hash;
        if (numberOrArray === 1 || numberOrArray.length === 1) {
            return t(key, hash);
        } else {
            if (I18n.lookup(key + "_plural")) {
                return t(key + "_plural", hash);
            } else {
                return t(key, hash) + "s";
            }
        }
    },

    renderTableData: function(tableData) {
        if (tableData && typeof(tableData) === 'string') {
            tableData = tableData.trim();
        }
        if (tableData || tableData === 0 || isNaN(tableData)) {
            return tableData;
        } else if (tableData === false) {
            return "false";
        } else {
            return new Handlebars.SafeString("&nbsp;");
        }
    },

    encode: function(value) {
        return encodeURIComponent(value);
    },

    unsafeT: function() {
        return new Handlebars.SafeString(Handlebars.helpers.t.apply(this, arguments));
    },

    hotKeyName: function(hotKeyChar) {
        return _.capitalize(chorus.hotKeyMeta) + " + " + hotKeyChar;
    }
};

_.each(chorus.handlebarsHelpers.string, function(helper, name) {
    Handlebars.registerHelper(name, helper);
});