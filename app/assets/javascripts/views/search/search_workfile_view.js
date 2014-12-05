chorus.views.SearchWorkfile = chorus.views.SearchItemBase.extend({
    constructorName: "SearchWorkfileView",
    templateName: "search_workfile",

    additionalContext: function () {
        return _.extend(this._super("additionalContext"), {
            showUrl: this.model.showUrl(),
            iconUrl: this.model.iconUrl(),
            workspaces: [this.model.workspace().attributes]
        });
    },

    makeCommentList: function (){
        var comments = this.model.get("comments") || [];
        var versionComments = this.model.get("highlightedAttributes") && this.model.get("highlightedAttributes").versionComments;
        _.each(versionComments || [], function(versionComment) {
            comments.push({isVersionComment:true, body: new Handlebars.SafeString(versionComment)});
        }, this);

        return new chorus.views.SearchResultCommentList({comments: comments});
    }
});