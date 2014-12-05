chorus.models.Insight = chorus.models.Note.extend({
    constructorName: "Insight",
    parameterWrapper: "note",

    urlTemplate:function (options) {
        var action = this.get('action');

        if (options && options.isFile) {
            return "notes/{{id}}/attachments";
        } else if (action === "create") {
            return "insights";
        } else if (action === "publish" || action === "unpublish") {
            return "insights/" + action;
        } else if (action === "destroy") {
            return "insights/{{id}}";
        } else {
            return "notes/{{id}}";
        }
    },
    
    initialize: function() {
        this._super('initialize');
        this.set({ isInsight: true });
    },

    declareValidations:function (newAttrs) {
        if (newAttrs['validateBody'] !== false) {
            this.require('body', newAttrs);
        }
    }
});
