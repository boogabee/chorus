chorus.Mixins.TagsContext = {

    additionalContextForTags: function () {
        var self = this;
        var presentedTags = this.model.tags().map(function (tag) {
            return {
                tagLink: tag.showUrl(self.options && self.options.workspaceIdForTagLink),
                tagName: tag.name()
            };
        });

        return { tags: presentedTags };
    }
};
