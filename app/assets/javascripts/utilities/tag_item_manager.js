(function () {
    var TagItemManager = chorus.utilities.TagItemManager = function () {};

    TagItemManager.prototype = {
        init: function (core) {},

        filter: function (list, query) {
            return list;
        },

        itemContains: function (item, needle) {
            return true;
        },

        stringToItem: function (str) {
            return {name: str};
        },

        itemToString: function (item) {
            return item.name;
        },

        compareItems: function (item1, item2) {
            return _.strip(item1.name.toLowerCase()) === _.strip(item2.name.toLowerCase());
        }
    };
})();