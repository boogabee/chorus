chorus.views.WorkspaceSummaryContentHeader = chorus.views.Base.extend({
    constructorName: "WorkspaceSummaryContentHeaderView",
    templateName: "workspace_summary_content_header",
    additionalClass: 'taggable_header',
    useLoadingSection: true,

    subviews: {
        ".truncated_summary": "truncatedSummary",
        ".project_status": "projectStatus",
        ".activity_list_header": "activityListHeader"
    },

    setup: function() {
        this.model.activities().fetchIfNotLoaded();
        this.requiredResources.push(this.model);
        this.listenTo(this.model, "saved", this.updateHeaderAndActivityList);
    },

    updateHeaderAndActivityList: function() {
        this.resourcesLoaded();
        this.render();
    },

    resourcesLoaded : function() {
        this.truncatedSummary = new chorus.views.TruncatedText({model:this.model, attribute:"summary", attributeIsHtmlSafe: true, extraLine: true});
        this.activityListHeader = new chorus.views.ActivityListHeader({
            model: this.model,
            allTitle: this.model.get("name"),
            insightsTitle: this.model.get("name"),
            tagBox: new chorus.views.TagBox({
                model: this.model,
                workspaceIdForTagLink: this.model.id
            })
        });
        this.projectStatus = new chorus.views.ProjectStatus({model:this.model});
    },

    postRender: function() {
        if(this.model.get("summary")) {
            this.$(".truncated_summary").removeClass("hidden");
        } else {
            this.$(".truncated_summary").addClass("hidden");
        }
    }
});