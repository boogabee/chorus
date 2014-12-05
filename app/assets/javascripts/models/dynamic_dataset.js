chorus.models.DynamicDataset = function (attributes) {
    if (attributes) {
        if (attributes.entitySubtype === "CHORUS_VIEW") return new chorus.models.ChorusView(attributes);
        if (attributes.entitySubtype === "HDFS") return new chorus.models.HdfsDataset(attributes);
        if (attributes.workspace) return new chorus.models.WorkspaceDataset(attributes);
    }
    return new chorus.models.Dataset(attributes);
};