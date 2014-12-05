chorus.pages.DataSourceIndexPage = chorus.pages.Base.extend({
    crumbs:[
        { label:t("breadcrumbs.home"), url:"#/" },
        { label:t("breadcrumbs.data_sources") }
    ],
    helpId: "instances",

    setup:function () {
        var dataSources = new chorus.collections.DataSourceSet([], {all: true});
        var hdfsDataSources = new chorus.collections.HdfsDataSourceSet();
        var gnipDataSources = new chorus.collections.GnipDataSourceSet();

        dataSources.fetchAll();
        hdfsDataSources.fetchAll();
        gnipDataSources.fetchAll();

        this.handleFetchErrorsFor(dataSources);
        this.handleFetchErrorsFor(hdfsDataSources);
        this.handleFetchErrorsFor(gnipDataSources);

        var options = {
            dataSources: dataSources,
            hdfsDataSources: hdfsDataSources,
            gnipDataSources: gnipDataSources
        };

        this.mainContent = new chorus.views.MainContentView({
            contentHeader: new chorus.views.StaticTemplate("default_content_header", {title:t("data_sources.title_plural")}),
            contentDetails: new chorus.views.DataSourceIndexContentDetails(options),
            content: new chorus.views.DataSourceIndex(options)
        });

        this.sidebar = new chorus.views.DataSourceListSidebar();

        this.multiSelectSidebarMenu = new chorus.views.MultipleSelectionSidebarMenu({
            selectEvent: "data_source:checked",
            actionProvider: [ {name: 'edit_tags', target: chorus.dialogs.EditTags}]
        });

        this.subscribePageEvent("data_source:selected", this.setModel);
        this.subscribePageEvent("clear_selection", this.clearModel);
    },

    preRender: function () {
        var actions = [];

        var notRestricted = !chorus.models.Config.instance().restrictDataSourceCreation();
        if (notRestricted || chorus.session.user().get("admin")) {
            actions.push({name: 'add_data_source', target: chorus.dialogs.DataSourcesNew});
        }

        this.primaryActionPanel = new chorus.views.PrimaryActionPanel({actions: actions, pageModel: {}});
    },

    setModel:function (dataSource) {
        this.model = dataSource;
    },

    clearModel:function (dataSource) {
        delete this.model;
        this.sidebar.clear();
    }
});
