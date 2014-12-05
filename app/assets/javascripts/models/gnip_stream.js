chorus.models.GnipStream = chorus.models.Base.extend({
    constructorName: "GnipDataSource",
    urlTemplate: "gnip_data_sources/{{gnip_data_source_id}}/imports",
    parameterWrapper: "import",

    declareValidations: function(newAttrs) {
        this.requirePattern("toTable", chorus.ValidationRegexes.ChorusIdentifier(), newAttrs, "import.validation.toTable.required");
        this.require("workspaceId", newAttrs);
    }
});