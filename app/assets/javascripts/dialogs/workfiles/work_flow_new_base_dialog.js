chorus.dialogs.WorkFlowNewBase = chorus.dialogs.Base.include(chorus.Mixins.DialogFormHelpers).extend({
    templateName: "work_flow_new",
    title: t("work_flows.new_dialog.title"),
    persistent: true,

    additionalContext: function () {
        return {
            userWillPickSchema: this.userWillPickSchema
        };
    },

    setup: function() {
        this.model = this.resource = new chorus.models.AlpineWorkfile({
            workspace: {id: this.options.pageModel.id }
        });
        this.disableFormUnlessValid({
            formSelector: "form",
            inputSelector: "input[name=fileName]",
            checkInput: _.bind(this.checkInput, this)
        });

        this.listenTo(this.resource, "saved", this.workfileSaved);
        this.listenTo(this.resource, "saveFailed", this.saveFailed);
    },

    create: function(e) {
        this.resource.set(this.resourceAttributes());

        this.$("button.submit").startLoading("actions.adding");
        this.resource.save();
    },

    getFileName: function() {
        return this.$("input[name=fileName]").val().trim();
    },

    workfileSaved: function() {
        this.closeModal();
        this.model.notifyWorkflowLimitedDataSource();
        chorus.router.navigate(this.resource.showUrl({workFlow: true}));
    }
});
