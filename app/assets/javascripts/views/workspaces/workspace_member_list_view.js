chorus.views.WorkspaceMemberList = chorus.views.Base.extend({
    constructorName: "WorkspaceMemberList",
    templateName: "workspace_member_list",
    numberOfMembersToShow: 24,

    events: {
        "click a.more_members": "launchWorkspaceMembersMoreDialog"
    },

    setup: function() {
        this.subscribePageEvent("workspace:selected", this.setWorkspace);
        if (this.options.collection) {
            this.setCollection(this.options.collection);
        }
    },

    additionalContext: function() {
        if (this.collection) {
            return {
                members: this.members(),
                extra_members: Math.max(this.collection.totalRecordCount() - this.numberOfMembersToShow, 0)
            };
        } else {
            return {};
        }
    },

    setCollection: function(collection) {
        this.setModel(collection);
        this.collection = collection;
        this.collection.fetchAllIfNotLoaded();
    },

    setWorkspace: function(workspace) {
        if (workspace) {
            this.setCollection(workspace.members());
        }
        this.render();
    },

    members: function () {
        function detailsForMember(member) {
            return {
                imageUrl: member.fetchImageUrl({ size: 'icon' }),
                showUrl: member.showUrl(),
                displayName: member.displayName()
            };
        }

        var collection = this.collection.chain().first(this.numberOfMembersToShow).map(detailsForMember);

        return collection.value();
    },

    launchWorkspaceMembersMoreDialog: function(e) {
        e && e.preventDefault();
        var dialog = new chorus.dialogs.WorkspaceMembersMore({
            collection: this.collection
        });
        dialog.launchModal();
    }
});
