chorus.views.Base = chorus.views.Bare.extend({
    collectionModelContext: $.noop,
    additionalContext: function() {
        return {};
    },

    //Bind various callbacks to the view's resource (model or collection)
    bindCallbacks: function() {
        if (this.resource) {
            this.listenTo(this.resource, "saveFailed validationFailed", this.showErrors);
            this.listenTo(this.resource, "validated", this.clearErrors);
            if (!this.persistent) {
                this.listenTo(this.resource, "reset sort", this.render);

                if (!this.suppressRenderOnChange) {
                    this.listenTo(this.resource, "change", this.render);
                }
            }
        }
    },

    //Remove default bindings from view
    unbindCallbacks: function() {
        if(this.resource) {
            this.stopListening(this.resource, "saveFailed", this.showErrors);
            this.stopListening(this.resource, "validationFailed", this.showErrors);
            this.stopListening(this.resource, "validated", this.clearErrors);
            this.stopListening(this.resource, "change", this.render);
            this.stopListening(this.resource, "reset", this.render);
            this.stopListening(this.resource, "sort", this.render);
        }
    },

    //A JSON object with view attributes for handlebars to render within.
    context: function context(resource) {
        resource = resource || this.resource;
        var ctx;
        var self = this;

        if (resource) {
            ctx = _.clone(resource.attributes);
            ctx.resource = resource;
            ctx.loaded = resource.loaded;
            if (this.collection) {
                ctx.models = _.map(this.collection.models, function(model) {
                    return _.extend({model: model}, model.attributes, self.collectionModelContext(model));
                });
            }
            if (resource.serverErrors) ctx.serverErrors = resource.serverErrors;
            $.extend(ctx, this.additionalContext(ctx));
        } else {
            ctx = this.additionalContext({});
        }

        ctx.view = self;
        return ctx;
    },

    render: function() {
        var result = this._super('render', arguments);
        chorus.placeholder(this.$("input[placeholder], textarea[placeholder]"));
        return result;
    },

    displayLoadingSection: function() {
        if (!this.useLoadingSection) {
            return false;
        }
        if (this.requiredResources.length > 0) {
            return !this.requiredResources.allResponded();
        } else {
            return this.resource && !this.resource.loaded;
        }
    },

    showErrors: function(model) {
        var self = this;

        var isModal = $(this.el).closest(".dialog").length;

        this.clearErrors();

        model = model || this.resource;
        if (!model) { return; }

        _.each(model.errors, function(val, key) {
            var $input = self.$("input[name=" + key + "], form textarea[name=" + key + "]");
            self.markInputAsInvalid($input, val, isModal);
        });
        this.displayServerErrors(model);
    },

    displayServerErrors: function(model) {
        this.$(".errors").replaceWith(Handlebars.VM.invokePartial(Handlebars.partials.errorDiv, "errorDiv", this.context(model), Handlebars.helpers, Handlebars.partials));
        this.$(".errors").removeClass("hidden");
    },

    markInputAsInvalid: function($input, message, isModal) {
        var classes = isModal ? "tooltip-error tooltip-modal" : "tooltip-error";
        $input.addClass("has_error");
        $input.qtip({
            content: {
                text: message
            },
            show: 'mouseover focus',
            hide: 'mouseout blur',
            style: {
                classes: classes,
                tip: {
                    width: 12,
                    height: 12
                }
            },
            position: {
                my: "left center",
                at: "right center",
                container: this.el
            }
        });
    },

    clearErrors: function() {
        this.clearPopupErrors();
        this.$(".errors").empty().addClass("hidden");
    },

    clearPopupErrors: function() {
        var errors = this.$(".has_error");
        errors.qtip("destroy");
        errors.removeData("qtip");
        errors.removeClass("has_error");
    },

    setModel: function(model) {
        this.unbindCallbacks();
        this.resource = this.model = model;
        this.bindCallbacks();
    }
});
