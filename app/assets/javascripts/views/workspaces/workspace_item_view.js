chorus.views.WorkspaceItem = chorus.views.Base.include(chorus.Mixins.TagsContext).extend({
    constructorName: "WorkspaceItemView",
    templateName: "workspace_item",
    tagName: "div",

    subviews: {
        ".summary": "summary"
    },

    additionalContext: function() {
        return _.extend(this.additionalContextForTags(), {
            iconUrl: this.model.defaultIconUrl(),
            url: this.model.showUrl(),
            ownerUrl: this.model.owner().showUrl(),
            archiverUrl: this.model.archiver().showUrl(),
            archiverFullName: this.model.archiver().displayName(),
            ownerFullName: this.model.owner().displayName(),
            active: this.model.isActive(),
            isWorkspace: true
        });
    },

    summary: function() {
        return new chorus.views.TruncatedText({model: this.model, attribute: "summary", attributeIsHtmlSafe: true});
    },

    postRender: function() {
        $(this.el).attr("data-id", this.model.id);

        if(!this.model.isActive()) {
            $(this.el).addClass("archived");
        }
    }
});
