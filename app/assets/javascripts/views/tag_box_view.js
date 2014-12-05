chorus.views.TagBox = chorus.views.Base.extend({
    templateName: "tag_box",
    constructorName: "TagBoxView",
    subviews: {'.tags_input': 'tagsInput'},

    setup: function() {
        this.requiredResources.add(this.model);
        this.tags = this.model.tags();
        this.tagsInput = new chorus.views.TagsInput({tags: this.tags, taggable: this.model});
        this.listenTo(this.tagsInput, "tag:click", this.navigateToTagShowPage);
    },

    navigateToTagShowPage: function(tag) {
       // this ensures url fragment has an initial slash in browser address bar
        var url = tag.showUrl(this.options.workspaceIdForTagLink).replace("#","#/");
        chorus.router.navigate(url);
    },

    resourcesLoaded: function() {
        this.tags.reset(this.model.get("tags"));
    }
});
