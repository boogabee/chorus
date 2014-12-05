chorus.handlebarsHelpers.search = {
    displaySearchMatch: function(attributeName) {
        var attr = Handlebars.helpers.withSearchResults(this).get(attributeName, false);
        if (attr) {
            return new Handlebars.SafeString(attr);
        }
        return attr;
    },

    displaySearchMatchFromSafeField: function(attributeName) {
        var attr = Handlebars.helpers.withSearchResults(this).get(attributeName, true);
        if (attr) {
            return new Handlebars.SafeString(attr);
        }
        return attr;
    },

    withSearchResults: function(modelOrAttributes) {
        var getReal = modelOrAttributes.get || function(attributeName) { return modelOrAttributes[attributeName]; };
        modelOrAttributes = Object.create(modelOrAttributes);

        modelOrAttributes.get =
            function(attributeName, safe) {
                if (getReal.call(modelOrAttributes, 'highlightedAttributes') && getReal.call(modelOrAttributes, 'highlightedAttributes')[attributeName]) {
                    var attribute = getReal.call(modelOrAttributes, 'highlightedAttributes')[attributeName];
                    return new Handlebars.SafeString(_.isArray(attribute) ? attribute[0] : attribute);
                } else if (safe) {
                    return new Handlebars.SafeString(modelOrAttributes[attributeName]);
                } else {
                    return new Handlebars.SafeString(Handlebars.Utils.escapeExpression(getReal.call(modelOrAttributes, attributeName)));
                }
            };

        return modelOrAttributes;
    },

    searchResultCommentTitle: function(comment) {
        if (comment.isInsight) {
            return t("search.supporting_message_types.insight");
        }
        if (comment.isComment) {
            return t("search.supporting_message_types.comment");
        }
        if (comment.isVersionComment) {
            return t("search.supporting_message_types.version_comment");
        }
        if (comment.subType) {
            return t("search.supporting_message_types." + comment.subType);
        }
        return t("search.supporting_message_types.note");
    }
};

_.each(chorus.handlebarsHelpers.search, function(helper, name) {
    Handlebars.registerHelper(name, helper);
});
