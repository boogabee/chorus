chorus.views.DataSourceItem = chorus.views.Base.include(
        chorus.Mixins.TagsContext
    ).extend({
    constructorName: "DataSourceItemView",
    templateName: "data_source_item",

    additionalContext: function() {
        return _.extend(this.additionalContextForTags(), {
            stateUrl: this.model.stateIconUrl(),
            url: this.model.showUrl(),
            providerUrl: this.model.providerIconUrl(),
            stateText: this.model.stateText()
        });
    }
});