chorus.views.HdfsEntryHeader = chorus.views.Base.include(
        chorus.Mixins.HdfsViews
    ).extend({
    templateName: "hdfs_entry_header",

    setup: function(options) {
        this.dataSource = options.dataSource;
        this.hdfsEntry = options.hdfsEntry;
        this.requiredResources.add(this.dataSource);
        this.requiredResources.add(this.hdfsEntry);
    },

    additionalContext: function() {
        return {
            dataSourceName: this.dataSource.name(),
            path: this.ellipsizePath(),
            showTags: this.showTags()
        };
    },

    setupSubviews: function() {
        if(this.showTags()) {
            this.tagBox = this.tagBox || new chorus.views.TagBox({model: this.dataSource});
            this.subviews[".tag_box"] = 'tagBox';
        }
    },

    showTags: function() {
        return this.hdfsEntry.get('path') === '/' && this.hdfsEntry.get('name') === '/';
    }
});