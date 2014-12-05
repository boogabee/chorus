chorus.views.ListContentDetailsButtonView = chorus.views.Base.extend({
    templateName: "list_content_details_buttons",

    additionalContext: function() {
        return {
            buttons: this.options.buttons
        };
    }
});