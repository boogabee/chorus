chorus.views.UserSidebar = chorus.views.Sidebar.extend({
    templateName:"user/sidebar",
    entityType:"user",

    subviews:{
        '.tab_control': 'tabs'
    },

    events: {
        "click .edit_tags": "startEditingTags",
        "click .change_password": "launchChangePasswordDialog",
        "click .delete_user": "launchUserDeleteAlert"
    },

    setup: function() {
        this.config = chorus.models.Config.instance();

        this.tabs = new chorus.views.TabControl(["activity"]);
        if (this.model) this.setUser(this.model);

        this.subscribePageEvent("user:selected", this.setUser);
    },

    additionalContext:function () {
        var ctx = {};
        if (this.model) {
            var currentUserCanEdit = this.model.currentUserCanEdit();

            _.extend(ctx, {
                displayName: this.model.displayName(),
                permission: currentUserCanEdit,
                listMode: this.options.listMode,
                changePasswordAvailable: currentUserCanEdit && !this.config.isExternalAuth(),
                isInEditMode: this.options.editMode,
                deleteAvailable : this.model.currentUserCanDelete()
            });
        }

        return ctx;
    },

    setUser: function(user) {
        if (!user) return;
        this.resource = this.model = user;
        this.collection = this.model.activities();
        this.collection.fetch();
        this.listenTo(this.collection, "changed", this.render);

        this.tabs.activity && this.tabs.activity.teardown();
        this.tabs.activity = new chorus.views.ActivityList({ collection:this.collection, additionalClass:"sidebar" });
        this.registerSubView(this.tabs.activity);

        this.render();
    },

    startEditingTags: function(e) {
        e.preventDefault();
        new chorus.dialogs.EditTags({collection: new chorus.collections.Base([this.model])}).launchModal();
    },

    launchChangePasswordDialog: function(e) {
        e && e.preventDefault();
        var dialog = new chorus.dialogs.ChangePassword({
            model: this.model,
            username: this.model.get("username")
        });
        dialog.launchModal();
    },

    launchUserDeleteAlert: function(e) {
        e && e.preventDefault();
        var dialog = new chorus.alerts.UserDelete({
            model: this.model,
            id: this.model.id
        });
        dialog.launchModal();
    }
});
