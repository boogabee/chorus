chorus.views.WorkspaceShowSidebar = chorus.views.Sidebar.extend({
    constructorName: "WorkspaceShowSidebarView",
    templateName:"workspace_show_sidebar",

    subviews: {
        ".workspace_member_list": "workspaceMemberList"
    },

    setup:function () {
        this.listenTo(this.model, "image:change", this.render);
        this.workspaceMemberList = new chorus.views.WorkspaceMemberList({collection: this.model.members()});
    },

    additionalContext:function () {
        var license = chorus.models.Config.instance().license();
        return {
            workspaceAdmin:this.model.workspaceAdmin(),
            imageUrl:this.model.fetchImageUrl(),
            hasImage:this.model.hasImage(),
            hasSandbox:!!this.model.sandbox(),
            limitSandboxes: license.limitSandboxes(),
            canUpdate: this.model.canUpdate(),
            active: this.model.isActive(),
            canKaggle: chorus.models.Config.instance().get("kaggleConfigured") && this.model.canUpdate() && this.model.isActive(),
            kaggleUrl: this.model.showUrl()+"/kaggle",
            limitWorkspaceMembership: license.limitWorkspaceMembership()
        };
    },

    postRender:function () {
        var self = this;
        this.$(".workspace_image").load(function () {
            self.$(".after_image").removeClass("hidden");
        });
        this.$('.workspace_image').load(_.bind(this.recalculateScrolling, this));
        this._super('postRender');
    },

    launchEditWorkspaceDialog: function (e) {
        e && e.preventDefault();

        this.editWorkspaceDialog = new chorus.dialogs.EditWorkspace({model: this.model});
        this.onceLoaded(this.model.members(), function () {
            this.editWorkspaceDialog.launchModal();
        });
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

    launchSandboxNewDialog: function(e) {
        e && e.preventDefault();
        var dialog = new chorus.dialogs.SandboxNew({workspaceId: this.model.id});
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
    },

    launchWorkspaceEditMembersDialog: function(e) {
        e && e.preventDefault();
        var dialog = new chorus.dialogs.WorkspaceEditMembers({pageModel: this.model});
        dialog.launchModal();
    },

    launchWorkspaceDeleteAlert: function(e) {
        e && e.preventDefault();
        var alert = new chorus.alerts.WorkspaceDelete({model: this.model});
        alert.launchModal();
    }
});
