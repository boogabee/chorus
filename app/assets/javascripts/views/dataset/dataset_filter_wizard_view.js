chorus.views.DatasetFilterWizard = chorus.views.FilterWizard.extend({
    title: "dataset.filter.title",
    constructorName: "DatasetFilterWizard",

    filterView: function(filter) {
        return new chorus.views.DatasetFilter({model: filter, collection: this.columnSet, showAliasedName: this.options.showAliasedName});
    },

    filterModel: function() {
        return new chorus.models.DatasetFilter();
    },

    filterCollection: function() {
        return new chorus.collections.DatasetFilterSet();
    }
});
