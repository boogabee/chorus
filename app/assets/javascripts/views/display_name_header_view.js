chorus.views.DisplayNameHeader = chorus.views.Base.extend({
    constructorName: "DisplayNameHeaderView",
    templateName:"default_content_header",

    subviews: {
        '.tag_box': 'tagBox'
    },

    setup: function(options) {
        this.tagBox = options.showTagBox && new chorus.views.TagBox({
            model: this.model,
            workspaceIdForTagLink: this.options.workspaceId
        });
    },

    additionalContext:function (ctx) {
        return {
            title:this.model && this.model.loaded ? this.model.displayName() : "",
            imageUrl: this.options.imageUrl,
            showTagBox: this.options.showTagBox
        };
    }
});