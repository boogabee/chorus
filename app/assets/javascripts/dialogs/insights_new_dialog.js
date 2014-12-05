chorus.dialogs.InsightsNew = chorus.dialogs.MemoNew.extend({
    title:t("insight.new_dialog.title"),
    placeholder: t("insight.placeholder"),
    submitButton: t("insight.button.create"),

    events: {
        "click button.submit": "save"
    },

    setup: function (options) {
        _.extend(options, {allowWorkspaceAttachments: true});
        this._super("setup", arguments);
    },

    makeModel:function () {
        this.pageModel = this.options.pageModel;

        this.model = new chorus.models.Insight({
            entityType: this.pageModel.entityType,
            entityId: this.pageModel.id,
            workspaceId: this.pageModel.id
        });
        this._super("makeModel", arguments);
    }
});
