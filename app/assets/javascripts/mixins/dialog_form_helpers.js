chorus.Mixins.DialogFormHelpers = {
    disableFormUnlessValid: function(options) {
        var events = {};
        if (options.checkInput) {
            this.formCheckFn = options.checkInput;
        } else {
            this.formCheckFn = _.bind(function() {
                return this.$(options.inputSelector).val().trim().length > 0;
            }, this);
        }

        this.toggleSubmitDisabled = _.bind(function() {
            this.$("button.submit").prop("disabled", this.formCheckFn() ? false : "disabled");
        }, this);

        events["keyup " + options.inputSelector] = this.toggleSubmitDisabled;
        events["paste " + options.inputSelector] = this.toggleSubmitDisabled;
        events["submit " + options.formSelector] = "onFormSubmit";
        this.events = _.extend(events, this.events || {});
    },

    onFormSubmit: function(e) {
        e.preventDefault();
        e.stopPropagation();

        if (this.formCheckFn()) {
            this.create(e);
        }
        return false;
    }
};
