chorus.dialogs.ChangePassword = chorus.dialogs.Base.extend({
    templateName:"change_password",
    title:t("user.change_password.title"),
    events:{
        "submit form":"save"
    },
    persistent:true,

    save:function (e) {
        e && e.preventDefault();

        this.listenTo(this.model, "saved", this.saved);
        this.model.save({
            password:this.$("input[name=password]").val(),
            passwordConfirmation:this.$("input[name=passwordConfirmation]").val()
        });
    },

    saved:function () {
        this.closeModal();
    }
});
