chorus.views.SearchWorkspace = chorus.views.SearchItemBase.extend({
    constructorName: "SearchWorkspaceView",
    templateName: "search_workspace",

    additionalContext: function(){
        return _.extend(this._super("additionalContext"), {
            showUrl: this.model.showUrl(),
            iconUrl: this.model.defaultIconUrl()
        });
    }
});
