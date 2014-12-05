chorus.alerts.Confirm = chorus.alerts.Base.extend({
    constructorName: "ConfirmAlert",

    focusSelector: "button.submit",

    postRender: function() {
        this._super('postRender');
        this.$("button.submit").removeClass('hidden');
    }
});