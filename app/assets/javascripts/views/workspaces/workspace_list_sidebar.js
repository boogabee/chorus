chorus.views.WorkspaceListSidebar = chorus.views.Sidebar.extend({
    constructorName: "WorkspaceListSidebar",
    templateName: "workspace_list_sidebar",

    subviews: {
        '.tab_control': 'tabs',
        ".workspace_member_list": "workspaceMemberList"
    },

    events: {
        "click .edit_tags": 'startEditingTags',
        "click a.new_note": 'launchNotesNewDialog',
        "click a.new_insight": 'launchInsightsNewDialog'
    },

    setup: function() {
        this.subscribePageEvent("workspace:selected", this.setWorkspace);
        this.tabs = new chorus.views.TabControl(["activity"]);
        this.workspaceMemberList = new chorus.views.WorkspaceMemberList();
    },

    additionalContext: function() {
        return this.model ? {
            imageSrc: this.model.fetchImageUrl(),
            hasImage: this.model.hasImage(),
            prettyName: $.stripHtml(this.model.get("name")),
            showAddNoteInsightLinks: !!this.model
        } : {};
    },

    setWorkspace: function(model) {
        this.resource = this.model = model;

        if(this.tabs.activity) {
            this.tabs.activity.teardown();
        }

        if (model) {
            if(this.activities) {
                this.stopListening(this.activities);
            }

            this.activities = model.activities();
            this.activities.fetch();

            this.listenTo(this.activities, "changed", this.render);
            this.listenTo(this.activities, "reset", this.render);

            this.tabs.activity = new chorus.views.ActivityList({
                collection: this.activities,
                additionalClass: "sidebar"
            });
            this.registerSubView(this.tabs.activity);
        } else {
            delete this.tabs.activity;
        }

        this.render();
    },

    startEditingTags: function(e) {
        e.preventDefault();
        new chorus.dialogs.EditTags({collection: new chorus.collections.Base([this.model])}).launchModal();
    },

    launchNotesNewDialog: function(e) {
        e && e.preventDefault();
        var dialog = new chorus.dialogs.NotesNew({
            pageModel: this.model,
            entityId: this.model.id,
            entityType: "workspace",
            workspaceId: this.model.id,
            allowWorkspaceAttachments: true
        });
        dialog.launchModal();
    },

    launchInsightsNewDialog: function(e) {
        e && e.preventDefault();
        var dialog = new chorus.dialogs.InsightsNew({
            pageModel: this.model,
            entityId: this.model.id,
            entityType: "workspace",
            workspaceId: this.model.id,
            allowWorkspaceAttachments: true
        });
        dialog.launchModal();
    }
});
