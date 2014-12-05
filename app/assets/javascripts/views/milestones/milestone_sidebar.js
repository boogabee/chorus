chorus.views.MilestoneSidebar = chorus.views.Sidebar.extend({
    constructorName: "MilestoneSidebar",
    templateName: "milestone_sidebar",

    subviews:{
        '.tab_control': 'tabs'
    },

    events: {
        'click a.delete_milestone': 'launchDeleteAlert',
        'click a.toggle_state': 'toggleState'
    },

    setup: function() {
    },

    additionalContext: function () {
        return this.model ? {
            canUpdate: this.model.workspace().canUpdate(),
            stateToggleKey: 'milestone.actions.toggle.' + this.model.get('state')
        } : {};
    },

    launchDeleteAlert: function (e) {
        e && e.preventDefault();
        new chorus.alerts.MilestoneDelete({model: this.model}).launchModal();
    },

    toggleState: function (e) {
        e && e.preventDefault();
        this.model.toggleState();
    }
});
