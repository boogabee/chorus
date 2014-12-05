chorus.dialogs.RenameTag = chorus.dialogs.Base.extend({
    constructorName: "RenameTagDialog",
    templateName: "rename_tag",
    title: t("rename_tag.title"),

    events: {
        "submit form" : "submit",
        "keyup input": "checkInput"
    },

    setup: function() {
        this.listenTo(this.model, "saveFailed", this.saveFailed);
        this.listenTo(this.model, "saved", this.saved);
    },

    postRender: function() {
        this.input = this.$(".rename_tag_input");
        this.submitButton = this.$("button.submit");
    },

    getName: function() {
        return this.input.val().trim();
    },

    submit: function(e) {
        e.preventDefault();
        this.submitButton.startLoading("actions.renaming");
        this.model.save({name: this.getName()}, {silent: true, unprocessableEntity: function() {
            // skip the default redirection on unprocessable entity
        }});
    },

    saved:function () {
        this.model.trigger("change");
        chorus.toast("tag.rename", {name: this.model.name()});
        this.closeModal();
    },

    checkInput : function() {
        this.clearErrors();
        var newAttributes = _.extend(_.clone(this.model.attributes), {
            name: this.getName()
        });
        var valid = this.model.performValidation(newAttributes);
        if (!valid) {
            this.markInputAsInvalid(this.input, this.model.errors.name, true);
        }
        this.submitButton.prop("disabled", !valid);
    }
});