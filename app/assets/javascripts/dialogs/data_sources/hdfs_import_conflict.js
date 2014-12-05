chorus.dialogs.HdfsImportConflict = chorus.dialogs.Base.include(chorus.Mixins.DialogFormHelpers).extend({
    constructorName: "HdfsImportConflict",
    templateName: "hdfs_import_conflict",
    title: t("hdfs.import.dialog.title"),

    makeModel: function () {
        this.model = this.options.model;
    },

    setup:function () {
        this.listenTo(this.resource, "saved", this.saved);
        this.listenTo(this.resource, "saveFailed", this.saveFailed);
        this.disableFormUnlessValid({
            formSelector: "form",
            inputSelector: "input[name=fileName]"
        });
    },

    create: function() {
        var fileName = this.$("input[name=fileName]").val().trim();

        this.resource.set({
            fileName: fileName
        });

        this.$("button.submit").startLoading("actions.creating");
        this.resource.save();
    },

    saved: function () {
        chorus.toast("hdfs.import.started");
        this.closeModal();
    },

    saveFailed: function () {
        this._super("saveFailed", arguments);
        this.$("button.submit").prop("disabled", "disabled");
    }
});
