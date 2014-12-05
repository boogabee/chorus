chorus.models.Comment = chorus.models.Activity.extend({
    constructorName: "Comment",
    entityType: 'comment',

    urlTemplate:function (options) {
        return "comments/{{id}}";
    },

    initialize:function () {
        this._super('initialize', arguments);
        this.files = [];
    },

    declareValidations:function (newAttrs) {
        this.require('body', newAttrs);
    },

    attrToLabel:{
        "body":"notes.body"
    },

    note: function() {
        return this.get('type') && this.get("type") === "NOTE";
    }
});
