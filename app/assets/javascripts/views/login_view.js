chorus.views.Login = chorus.views.Base.extend({
    constructorName: "LoginView",
    templateName:"login",
    events:{
        "submit form":"submitLoginForm"
    },

    persistent:true,
    warning: null,

    setup: function () {
        this.status = new chorus.models.Status();
        this.status.fetch();
        this.onceLoaded(this.status, this.processStatus);
        this.listenTo(this.model, "saved", this.onLogin);
    },

    additionalContext: function() {
        return {
            branding: this.branding(),
            logo: this.branding() + "-logo.png",
            copyright: t("login." + this.branding() + "_copyright", {year:moment().year()}),
            warning: this.warning
        };
    },

    postRender: function() {
        _.defer(_.bind(function() { this.$("input[name='username']").focus(); }, this));
    },

    onLogin: function () {
        var targetDestination;
        if (chorus.session && chorus.session.shouldResume()) {
            targetDestination = chorus.session.resumePath();
        } else {
            targetDestination = "/";
        }
        chorus.router.navigate(targetDestination);
    },

    submitLoginForm: function submitLoginForm(e) {
        e.preventDefault();
        this.model.clear({ silent:true });
        delete this.model.id;
        this.model.set({
            username:this.$("input[name='username']").val(),
            password:this.$("input[name='password']").val()
        });
        this.model.save();
    },

    branding: function() {
        return chorus.models.Config.instance().license().branding();
    },

    processStatus: function() {
        if (this.status.get("userCountExceeded")) {
            this.warning = {message: t("warn.user_count_exceeded")};
            this.render();
        }
    }
});