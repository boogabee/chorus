chorus.views.MilestoneItem = chorus.views.Base.extend({
    constructorName: "MilestoneItemView",
    templateName: "milestone_item",

    events: {
    },

    setup: function() {
        this._super("setup", arguments);
        this.listenTo(this.model, "invalidated", function() { this.model.fetch(); });
    },

    additionalContext: function () {
        return {
            checkable: false,
            stateKey: 'workspace.project.milestones.states.' + this.model.get('state'),
            iconUrl: '/images/milestones/milestone_' + (this.model.get('state') === 'planned' ? 'incomplete' : 'complete')  + '.png'
        };
    },

    postRender: function() {
        this.$(".loading_spinner").startLoading(null, {color: '#959595'});
    }
});