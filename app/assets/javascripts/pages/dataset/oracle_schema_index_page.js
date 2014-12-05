chorus.pages.OracleSchemaIndexPage = chorus.pages.Base.include(
        chorus.Mixins.DataSourceCredentials.page
).extend({
    setup: function(oracleDataSourceId){
        this.dataSource = new chorus.models.OracleDataSource({id: oracleDataSourceId});
        this.collection = this.dataSource.schemas();
        this.dataSource.fetch();
        this.collection.fetch();
        this.requiredResources.add(this.dataSource);

        this.handleFetchErrorsFor(this.collection);

        this.mainContent = new chorus.views.MainContentList({
            modelClass: "Schema",
            contentHeader: new chorus.views.TaggableHeader({model: this.dataSource}),
            collection: this.collection,
            search: {
                selector: ".name",
                placeholder: t("schema.search_placeholder"),
                eventName: "schema:search"
            }
        });

        this.sidebar = new chorus.views.SchemaListSidebar();
        this.breadcrumbs.requiredResources.add(this.dataSource);
    },

    crumbs: function() {
        return [
            { label: t("breadcrumbs.home"), url: "#/" },
            { label: t("breadcrumbs.data_sources"), url: "#/data_sources" },
            { label: this.dataSource.name() }
        ];
    }
});