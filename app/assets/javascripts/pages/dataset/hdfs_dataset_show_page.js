chorus.pages.HdfsDatasetShowPage = chorus.pages.Base.extend({
    constructorName: "HdfsDatasetShowPage",
    helpId: "dataset",

    failurePageOptions: function() {
        return {
            title: t('invalid_route.hadoop_dataset.title'),
            text: t('invalid_route.hadoop_dataset.content')
        };
    },

    makeModel: function(workspaceId, datasetId) {
        this.loadWorkspace(workspaceId, {required: true});
        this.model = this.dataset = new chorus.models.HdfsDataset({ workspace: { id: workspaceId }, id: datasetId });
    },

    setup: function() {
        this.model.fetch();

        this.mainContent = new chorus.views.LoadingSection();
        this.listenTo(this.model, "loaded", this.setupMainContent);
        this.listenTo(this.model, "invalidated", function () {
            this.model.fetch();
        });
        this.handleFetchErrorsFor(this.model);

        this.subNav = new chorus.views.SubNav({workspace: this.workspace, tab: "datasets"});
    },

    setupMainContent: function() {
        this.mainContent = new chorus.views.MainContentView({
            model: this.model,
            content: new chorus.views.ReadOnlyTextContent({model: this.model}),
            contentHeader: new chorus.views.DatasetShowContentHeader({ model: this.model }),
            contentDetails: new chorus.views.HdfsDatasetContentDetails({ model: this.model })
        });
        this.sidebar = new chorus.views.DatasetSidebar({ model: this.model });
        this.sidebar.setDataset(this.dataset);
        this.render();
    }
});
