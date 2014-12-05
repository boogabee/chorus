chorus.views.ReadOnlyWorkfileContentDetails = chorus.views.Base.extend({
    templateName: "read_only_workfile_content_details",
    constructorName: "ReadOnlyWorkfileContentDetailsView",
    additionalClass: "workfile_content_details action_bar_limited",

    additionalContext: function() {
        return {
            explanationText: this.explanationText,
            downloadUrl: this.model.downloadUrl()
        };
    }
});

chorus.views.BinaryWorkfileContentDetails = chorus.views.ReadOnlyWorkfileContentDetails.extend({
    constructorName: "BinaryWorkfileContentDetailsView",
    explanationText: t("workfile.not_previewable")
});

chorus.views.ArchivedWorkfileContentDetails = chorus.views.ReadOnlyWorkfileContentDetails.extend({
    constructorName: "ArchivedWorkfileContentDetailsView",
    explanationText: t("workfile.workspace_archived")
});

chorus.views.PartialWorkfileContentDetails = chorus.views.ReadOnlyWorkfileContentDetails.extend({
    constructorName: "PartialWorkfileContentDetailsView",
    explanationText: t("workfile.partial_file")
});
