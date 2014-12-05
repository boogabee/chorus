chorus.views.DatasetSidebar = chorus.views.Sidebar.extend({
    constructorName: "DatasetSidebarView",
    templateName: "dataset_sidebar",
    useLoadingSection: true,

    events: {
        "click .no_credentials a.add_credentials": "launchAddCredentialsDialog",
        "click .invalid_credentials a.update_credentials": "launchAddCredentialsDialog",
        "click a.associate": "launchAssociateWithWorkspaceDialog",
        "click a.dataset_preview": "launchDatasetPreviewDialog",
        "click a.analyze": "launchAnalyzeAlert",
        "click a.delete_dataset": "launchDatasetDeleteAlert",
        "click a.duplicate": "launchDuplicateChorusView",
        "click a.edit_tags": "startEditingTags",
        "click a.new_work_flow": "launchWorkFlowDialog",
        "click a.new_note": "launchNotesNewDialog",
        "click a.create_database_view": "launchCreateDatabaseViewDialog",
        "click a.import_now": "launchImportNowDialog",
        "click a.download": "launchDatasetDownloadDialog",
        "click a.edit_hdfs_dataset": "launchEditHdfsDatasetDialog",
        "click a.create_external_table": "launchCreateExternalTableFromHdfsDialog"
    },

    subviews: { '.tab_control': 'tabs' },

    setup: function() {
        this.subscribePageEvent("dataset:selected", this.setDataset);
        this.subscribePageEvent("column:selected", this.setColumn);
        this.subscribePageEvent("analyze:running", this.resetStatistics);
        this.subscribePageEvent("start:visualization", this.enterVisualizationMode);
        this.subscribePageEvent("cancel:visualization", this.endVisualizationMode);
        this.tabs = new chorus.views.TabControl(['activity', 'statistics']);
        this.registerSubView(this.tabs);
    },

    render: function() {
        if(!this.disabled) { this._super("render", arguments); }
    },

    setColumn: function(column) {
        if(column) {
            this.selectedColumn = column;
            this.tabs.statistics.column = column;
        } else {
            delete this.selectedColumn;
            delete this.tabs.statistics.column;
        }

        this.render();
    },

    createActivitiesTab: function(dataset) {
        var activities = dataset.activities();
        activities.fetch();

        this.tabs.activity = new chorus.views.ActivityList({
            collection: activities,
            additionalClass: "sidebar",
            displayStyle: ['without_workspace'],
            type: t("database_object." + dataset.get('objectType'))
        });
        this.tabs.registerSubView(this.tabs.activity);
    },

    createStatisticsTab: function(dataset) {
        this.tabs.statistics = new chorus.views.DatasetStatistics({
            model: dataset,
            column: this.selectedColumn
        });
        this.tabs.registerSubView(this.tabs.statistics);

        function fetchFailed() {
            if (this.tabs.statistics.statistics.statusCode === 403) {
                this.resource.invalidCredentials = true;
            }
            this.render();
        }

        this.listenTo(this.tabs.statistics.statistics, 'fetchFailed', fetchFailed);
    },

    fetchImports: function(dataset) {
        if(dataset.canBeImportSourceOrDestination()) {
            this.imports = dataset.getImports();
            this.listenTo(this.imports, "loaded", this.render);
            this.imports.fetch();
        }
    },

    setDataset: function(dataset) {
        this.resource = dataset;
        this.tabs.statistics && this.tabs.statistics.teardown();
        this.tabs.activity && this.tabs.activity.teardown();
        if(dataset) {
            this.createActivitiesTab(dataset);
            this.createStatisticsTab(dataset);
            this.fetchImports(dataset);
        } else {
            delete this.tabs.statistics;
            delete this.tabs.activity;
            delete this.imports;
        }

        this.render();
    },

    resetStatistics: function() {
        if (!this.resource.get('stale')) { this.resource.statistics().fetch(); }
    },

    additionalContext: function() {
        return new chorus.presenters.DatasetSidebar(this.resource, this.options);
    },

    postRender: function() {
        var $actionLinks = this.$("a.import_now, a.download, a.delete");
        $actionLinks.data("dataset", this.resource);
        $actionLinks.data("workspace", this.resource && this.resource.workspace());
        this._super("postRender");
    },

    launchAddCredentialsDialog: function(e) {
        e && e.preventDefault();
        new chorus.dialogs.DataSourceAccount({ dataSource: this.resource.dataSource(), title: t("data_sources.sidebar.add_credentials"), reload: true, goBack: false }).launchModal();
    },

    launchAssociateWithWorkspaceDialog: function(e) {
        e.preventDefault();

        new chorus.dialogs.AssociateWithWorkspace({model: this.resource, activeOnly: true}).launchModal();
    },

    launchDatasetPreviewDialog: function(e) {
        e.preventDefault();

        new chorus.dialogs.DatasetPreview({model: this.resource}).launchModal();
    },

    launchAnalyzeAlert: function(e) {
        e && e.preventDefault();
        new chorus.alerts.Analyze({model: this.resource}).launchModal();
    },

    launchDatasetDeleteAlert: function(e) {
        e && e.preventDefault();
        new chorus.alerts.DatasetDelete({pageModel: this.resource, keyPrefix: $(e.currentTarget).data("key-prefix")}).launchModal();
    },

    launchDuplicateChorusView: function(e) {
        e.preventDefault();
        var dialog = new chorus.dialogs.VerifyChorusView();
        dialog.setModel(this.resource.createDuplicateChorusView());
        dialog.launchModal();
    },

    launchWorkFlowDialog: function(e) {
        e && e.preventDefault();
        var dialog = new chorus.dialogs.WorkFlowNewForDatasetList({pageModel: this.resource.workspace(), collection: new chorus.collections.Base([this.resource])});
        dialog.launchModal();
    },

    launchNotesNewDialog: function(e) {
        e && e.preventDefault();
        var dialogOptions = {
            entityId: this.resource.id,
            entityType: "dataset",
            pageModel: this.resource,
            displayEntityType: this.resource.metaType()
        };

        if(this.resource.workspace()) {
            _.extend(dialogOptions, {
                workspaceId: this.resource.workspace().id,
                allowWorkspaceAttachments: true
            });
        }

        var dialog = new chorus.dialogs.NotesNew(dialogOptions);
        dialog.launchModal();
    },

    launchCreateDatabaseViewDialog: function(e) {
        e && e.preventDefault();
        var dialog = new chorus.dialogs.CreateDatabaseView({pageModel: this.resource});
        dialog.launchModal();
    },

    launchImportNowDialog: function(e) {
        e && e.preventDefault();
        var dialog = new chorus.dialogs.ImportNow({dataset: this.resource});
        dialog.launchModal();
    },

    launchDatasetDownloadDialog: function(e) {
        e && e.preventDefault();
        var dialog = new chorus.dialogs.DatasetDownload({pageModel: this.resource});
        dialog.launchModal();
    },

    launchEditHdfsDatasetDialog: function(e) {
        e && e.preventDefault();
        var dialog = new chorus.dialogs.EditHdfsDataset({model: this.resource});
        dialog.launchModal();
    },

    launchCreateExternalTableFromHdfsDialog: function (e) {
        e && e.preventDefault();

        this.resource.loaded = false;
        this.resource.fetch();
        this.onceLoaded(this.resource, function () {
            var dialogOptions = {
                model: new chorus.models.HdfsExternalTable({
                    hdfsDatasetId: this.resource.get('id'),
                    hdfsDataSourceId: this.resource.dataSource().get('id')
                }),
                csvOptions: {
                    tableName: this.resource.name(),
                    contents: this.resource.content()
                }
            };

            new chorus.dialogs.CreateExternalTableFromHdfs(dialogOptions).launchModal();
        });
    },


    enterVisualizationMode: function() {
        $(this.el).addClass("visualizing");
    },

    endVisualizationMode: function() {
        $(this.el).removeClass("visualizing");
    },

    startEditingTags: function(e) {
        e.preventDefault();
        new chorus.dialogs.EditTags({collection: new chorus.collections.Base([this.resource])}).launchModal();
    }
});