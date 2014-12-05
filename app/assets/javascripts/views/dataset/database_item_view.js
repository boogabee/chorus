chorus.views.DatabaseItem = chorus.views.Base.extend({
    constructorName: "DatabaseItemView",
    templateName: "database_item",
    tagName: "div",

    additionalContext: function() {
        return {
            url: this.model.showUrl(),
            checkable: false
        };
    }
});
