chorus.views.AlpineWorkfileContent = chorus.views.WorkfileContent.extend({
    templateName: "alpine_workfile_content",

    additionalContext: function () {
        return {
            imagePath: this.model.imageUrl()
        };
    }
});