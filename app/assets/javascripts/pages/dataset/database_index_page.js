chorus.pages.DatabaseIndexPage = chorus.pages.Base.include(
    chorus.Mixins.DataSourceCredentials.page
).extend({
    constructorName: "DatabaseIndexPage",
    helpId: "instances",

    setup: function(dataSourceId) {
        this.dataSource = new chorus.models.GpdbDataSource({id: dataSourceId});
        this.collection = this.dataSource.databases();

        this.dataSource.fetch();
        this.collection.fetchAll();

        this.handleFetchErrorsFor(this.dataSource);

        this.handleFetchErrorsFor(this.collection);

        this.mainContent = new chorus.views.MainContentList({
            emptyTitleBeforeFetch: true,
            modelClass: "Database",
            collection: this.collection,
            contentHeader: new chorus.views.TaggableHeader({model: this.dataSource}),
            search: {
                eventName: "database:search",
                placeholder: t("database.search_placeholder")
            }
        });

        this.sidebar = new chorus.views.DatabaseListSidebar();

        this.breadcrumbs.requiredResources.add(this.dataSource);
    },

    crumbs: function() {
        return [
            { label: t("breadcrumbs.home"), url: "#/" },
            { label: t("breadcrumbs.data_sources"), url: "#/data_sources" },
            { label: this.dataSource.get("name") }
        ];
    }
});
