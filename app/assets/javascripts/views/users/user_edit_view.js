(function () {
    function userSuccessfullySaved() {
        chorus.router.navigate(this.model.showUrl());
    }

    chorus.views.UserEdit = chorus.views.Base.extend({
        templateName:"user/edit",

        events:{
            "submit form":'saveEditUser',
            "click button.cancel":"goBack"
        },

        subviews:{
            '.edit_photo':"imageUpload"
        },

        setup:function () {
            this.listenTo(this.model, "saved", userSuccessfullySaved);
            this.listenTo(this.model, "image:change", function() { this.model.trigger("invalidated"); });
            this.imageUpload = new chorus.views.ImageUpload({ model:this.model, changeImageKey:"users.edit_photo" });
        },

        additionalContext:function () {
            return {
                permission:((this.model.get("username") === chorus.session.user().get("username")) || chorus.session.user().get("admin"))
            };
        },

        postRender: function() {
            this.$("textarea").limitMaxlength();
        },

        saveEditUser:function saveEditUser(e) {
            e.preventDefault();
            chorus.page.stopListening(this.model, "unprocessableEntity");
            var updates = {};
            _.each(this.$("input"), function (i) {
                var input = $(i);
                updates[input.attr("name")] = input.val().trim();
            });

            updates.admin = this.$("input#admin-checkbox").prop("checked") || false;
            updates.developer = this.$("input#developer-checkbox").prop("checked") || false;
            updates.subscribed_to_emails = this.$("input#subscribed-to-emails-checkbox").prop("checked") || false;
            updates.notes = this.$("textarea").val().trim();

            this.model.save(updates, {wait: true});
        },

        goBack:function () {
            window.history.back();
        }
    });
})();
