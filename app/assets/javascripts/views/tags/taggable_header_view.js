chorus.views.TaggableHeader = chorus.views.Base.extend({
    templateName: "taggable_header",
    constructorName: "TaggableHeaderView",

    subviews: {
        '.tag_box': 'tagBox'
    },

    setup: function () {
        this.tagBox = new chorus.views.TagBox({
            model: this.model
        });
    },

    additionalContext: function () {
        return {
            iconUrl: this.model.iconUrl()
        };
    }
});