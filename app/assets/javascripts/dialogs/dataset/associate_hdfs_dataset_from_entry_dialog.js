//= require ./hdfs_dataset_attributes_dialog.js

chorus.dialogs.AssociateHdfsDatasetFromEntry = chorus.dialogs.HdfsDatasetAttributes.extend({
    constructorName: 'AssociateHdfsDatasetFromEntryDialog',
    title: t('associate_hdfs_dataset_from_entry.title'),
    message: "associate_hdfs_dataset_from_entry.toast",
    events: {
        'click a.workspace_picked': 'launchWorkspacePicker'
    },

    setup: function () {
        this.options.entry = this.options.pageModel;
        this._super("setup");
    },

    findModel: function () {
        var dataSourceID = this.options.pageModel.get('hdfsDataSource').id;
        return new chorus.models.HdfsDataset({
            hdfsDataSource: new chorus.models.HdfsDataSource({id: dataSourceID})
        });
    },

    postRender: function() {
        this.$("input.name").val(this.options.entry.get('name'));
        this.$("input.file_mask").val(this.options.entry.getFullAbsolutePath());
    },

    launchWorkspacePicker: function (e) {
        e && e.preventDefault();
        var dialog = new chorus.dialogs.HdfsDatasetWorkspacePicker();
        this.listenTo(dialog, "workspace:selected", this.workspaceChosen);
        this.launchSubModal(dialog);
    },

    workspaceChosen: function (workspaces) {
        var workspace = workspaces && workspaces[0];
        if (workspace) {
            this.workspaceName = workspace.name();
            this.model.set({workspace: {id: workspace.id}, workspaceId: workspace.id}, {silent: true});
            this.$("a.workspace_picked").text(this.workspaceName);
            this.toggleSubmitDisabled();
        }
    },

    getDatasourceId: function () {
        return this.model.get('hdfsDataSource') && this.model.get('hdfsDataSource').id;
    },

    additionalContext: function () {
        return {
            needsWorkspace: true,
            workspaceName: this.workspaceName
        };
    },

    checkInput: function () {
        return this._super("checkInput") && this.checkWorkspace();
    },

    checkWorkspace: function () {
        return this.workspaceName || "";
    }
});