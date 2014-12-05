chorus.alerts.UserDelete = chorus.alerts.ModelDelete.extend({
    constructorName: "UserDelete",

    redirectUrl:"/users",
    text:t("user.delete.text"),
    title:t("user.delete.title"),
    ok:t("user.delete.button"),
    deleteMessage:"user.delete.toast",

    deleteModel: function(e) {
        chorus.page.stopListening(this.model, "unprocessableEntity");
        e.preventDefault();
        this.model.destroy();
        this.$("button.submit").startLoading("actions.deleting");
    },

    makeModel:function () {
        this.model = this.model || new chorus.models.User({ id: this.options.id });
    }
});
