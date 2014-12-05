chorus.dialogs.WorkfilesSqlNew = chorus.dialogs.Base.include(chorus.Mixins.DialogFormHelpers).extend({
    constructorName: "WorkfilesSqlNewDialog",

    templateName:"workfiles_sql_new",
    title:t("workfiles.sql_dialog.title"),

    persistent:true,

    makeModel:function () {
        this.model = this.model || new chorus.models.Workfile({
            workspace: {id: this.options.pageModel.id}
        });
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
            fileName:fileName ? fileName + ".sql" : ""
        });

        this.$("button.submit").startLoading("actions.adding");
        this.resource.save({source:"empty"});
    },

    saved:function () {
        this.closeModal();
        chorus.router.navigate(this.model.showUrl());
    }
});
