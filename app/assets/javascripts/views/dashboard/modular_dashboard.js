chorus.views.ModularDashboard = chorus.views.Base.extend({
    constructorName: "ModularDashboardView",
    templateName:"dashboard/module_list",

    makeModel: function () {
        this.model = new chorus.models.DashboardConfig({userId: chorus.session.user().id});
    },

    setup: function() {
        this.model.fetch();
    },

    preRender: function() {
        _.each(this.validModules(), function(moduleName, i) {
            this["module" + i] = new chorus.views["Dashboard" + moduleName]({content: moduleName});
        }, this);
    },

    setupSubviews: function () {
        _.each(this.validModules(true), function (moduleName, i) { this.subviews['.module_'+i] = 'module'+i; }, this);
    },

    additionalContext: function() {
        return { modules: this.validModules() };
    },

    validModules: function(warn) {
        return _.filter(this.model.get("modules"), function(moduleName, i) {
            var valid = chorus.views["Dashboard" + moduleName];
            warn && (valid || chorus.toast("bad_dashboard_module", {moduleName: moduleName, toastOpts: {type: "error"}}));
            return valid;
        }, this);
    }
});

