chorus.views.PrimaryActionPanel = chorus.views.Base.include(
    chorus.Mixins.ActionPanel
).extend({
    constructorName: "PrimaryActionPanel",
    templateName: "primary_action_panel",

    setup: function (options) {
        this.actions = this.options.actions || [];
        this.events = this.eventBindings(options.actions);
    },

    additionalContext: function () {
        return { actions: _.map(this.actions, this.templateValues) };
    }
});
