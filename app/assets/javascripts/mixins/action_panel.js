chorus.Mixins.ActionPanel = {
    eventBindings: function (actions, initialEvents) {
        var bindEvent = function (events, action) {
            events[("click a." + action.name)] = this.launcherFunction(action.target);
            return events;
        };

        return _.reduce(actions, bindEvent, initialEvents || {}, this);
    },

    templateValues: function (action) {
        return { name: action.name, message: t('actions.' + action.name) };
    },

    launcherFunction: function (target) {
        var dialogLauncher  = function (e) {
            e.preventDefault();
            new target({pageModel: this.options.pageModel, collection: this.selectedModels}).launchModal();
        };

        var navigator       = function (e) {
            e.preventDefault();
            chorus.router.navigate(target);
        };

        var invoker         = function (e) {
            e.preventDefault();
            this.selectedModels.invoke(target);
        };

        var targetIsConstructor = target instanceof Function;

        var targetIsURL = !targetIsConstructor && target.match(/\//);

        return targetIsConstructor ? dialogLauncher : targetIsURL ? navigator : invoker;
    }
};