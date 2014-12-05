chorus.alerts.WorkfileDraft = chorus.alerts.Confirm.extend({
    constructorName: "WorkfileDraft",

    text:t("workfile.alert.text"),
    title:t("workfile.alert.title"),
    ok:t("workfile.alert.open_draft"),
    cancel:t("workfile.alert.latest_version"),
    additionalClass:"info",

    confirmAlert:function () {
        var draft = new chorus.models.Draft({workspaceId:this.model.workspace().id, workfileId:this.model.get("id")});
        this.listenTo(draft, "change", function (draft) {
            this.closeModal();
            this.model.isDraft = true;
            this.model.content(draft.get("content"));
        });

        draft.fetch();
    },

    cancelAlert:function () {
        var draft = new chorus.models.Draft({workspaceId:this.model.workspace().id, workfileId:this.model.get("id"), id:"Dummy"});

        this.listenTo(draft, "change", function () {
            draft.destroy();
        });

        this.listenTo(draft, "destroy", function () {
            this.closeModal();
            this.model.set({ hasDraft:false });
        });

        draft.fetch();
    }
});

