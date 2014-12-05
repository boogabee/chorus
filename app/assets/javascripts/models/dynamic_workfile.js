chorus.models.DynamicWorkfile = function(workfileJson) {
    var typeMap = chorus.models.DynamicWorkfile.typeMap;

    if (!chorus.models[typeMap[workfileJson.entitySubtype]]) {
        return new chorus.models.Workfile(workfileJson);
    }

    return new chorus.models[typeMap[workfileJson.entitySubtype]](workfileJson);
};

chorus.models.DynamicWorkfile.typeMap = {
    alpine: 'AlpineWorkfile'
};