chorus.views.DataSourceIndexContentDetails = chorus.views.Base.include(
        chorus.Mixins.BoundForMultiSelect
    ).extend({
    constructorName: "DataSourceIndexContentDetailsView",
    templateName:"data_source_index_content_details",
    additionalClass: "action_bar_primary",

    events: {},

    setup: function(){
        this.dataSources = this.options.dataSources;
        this.hdfsDataSources = this.options.hdfsDataSources;
        this.gnipDataSources = this.options.gnipDataSources;

        this.listenTo(this.dataSources, 'loaded', this.render);
        this.listenTo(this.hdfsDataSources, 'loaded', this.render);
        this.listenTo(this.gnipDataSources, 'loaded', this.render);
    },

    postRender: function () {
        this.renderCheckedState();
    },

    additionalContext: function() {
        return {
            loaded: this.dataSources.loaded && this.gnipDataSources.loaded && this.hdfsDataSources.loaded,
            count: this.dataSources.length + this.hdfsDataSources.length + this.gnipDataSources.length
        };
    }
});