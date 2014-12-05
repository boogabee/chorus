chorus.views.SchemaItem = chorus.views.Base.extend(chorus.Mixins.TagsContext).extend({
    constructorName: "SchemaItemView",
    templateName: "schema_item",
    tagName: "div",

    additionalContext: function() {
        return {
            url: this.model.showUrl(),
            checkable: false,
            datasetCountMessage: (function(model) {
                var datasetCount = model.get('datasetCount');
                return model.get('refreshedAt') ? I18n.t("entity.name.WorkspaceDataset", {count: datasetCount}) : I18n.t("entity.name.WorkspaceDataset.refreshing");
            })(this.model)
        };
    }
});
