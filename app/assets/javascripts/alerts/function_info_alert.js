chorus.alerts.FunctionInfo = chorus.alerts.Base.extend({
    constructorName: "FunctionInfo",

    cancel: t("actions.close_window"),
    additionalClass: "info function_info",

    makeModel: function(options) {
        this.model = options.model;
    },

    preRender: function() {
        this.text = this.textContent();
        this.body = this.bodyContent();
    },

    bodyContent: function() {
        return Handlebars.helpers.renderTemplate("function_info_body", {
            definition: this.model.get("definition"),
            description: this.model.get("description")
        });
    },

    textContent: function() {
        return Handlebars.helpers.renderTemplate("function_info_text", {
            returnType: this.model.get('returnType'),
            name: this.model.get("name"),
            functionArguments: this.model.formattedArgumentList()
        });
    }
});
