chorus.collections.WorkfileVersionSet = chorus.collections.Base.include(chorus.Mixins.MultiModelSet).extend({
    constructorName: "WorkfileVersionSet",
    urlTemplate:"workfiles/{{workfileId}}/versions",
    model:chorus.models.Workfile,
    comparator:function (model) {
        return -model.get("versionInfo").versionNum;
    },

    // used by the MultiModelSet mixin
    idTemplate: function(model) {
        return model.id + "v" + model.get("versionInfo").versionNum;
    }

});