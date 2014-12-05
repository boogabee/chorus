chorus.collections.JobSet = chorus.collections.LastFetchWins.include(
    chorus.Mixins.CollectionFetchingSearch
	).extend({
    constructorName: "JobSet",
    model:chorus.models.Job,
    urlTemplate:"workspaces/{{workspaceId}}/jobs",
    searchAttr: "namePattern",

    urlParams: function() {
        return {
            namePattern: this.attributes.namePattern
        };
    }
});
