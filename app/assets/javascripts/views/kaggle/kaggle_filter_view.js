chorus.views.KaggleFilter = chorus.views.Filter.extend({
    templateName: "kaggle_filter",
    tagName: 'li',

    setup: function() {
        this.collection = this.collection || new chorus.collections.KaggleColumnSet();
        this.model = this.model || new chorus.models.KaggleFilter();
        this._super("setup", arguments);
        this.listenTo(this.columnFilter, "refresh", this.columnSelected);
    },

    postRender: function() {
        this.populateCompetitionType();
        this._super("postRender", arguments);
    },

    // TODO: populate the input values after the render or remove the filters

    populateCompetitionType: function() {
        // TODO: replace this with actual data from api once it's implemented
        var list = ["actuarial", "binary classification", "computer vision", "credit", "data manipulation",
            "exploratory", "finance", "government", "graph", "health", "high dimensionality", "insurance",
            "life sciences", "multiclass classification", "natural language processing", "public policy",
            "QSAR", "ranking", "regression", "research", "retail", "semi-supervised learning", "social",
            "start-ups", "supervised learning", "time series", "unstructured", "unsupervised learning",
            "visualization"];

        var $select = this.$(".filter.competition_type select");
        _.each(list, function(name, index) {
            var el = $("<option/>").text(name).attr("value", name);
            $select.append(el);
        }, this);

        if (this.model.get('input')) {
            this.$(".filter.competition_type select").val(this.model.get('input').value);
        }

        _.defer(function() {
            chorus.styleSelect($select, { menuWidth: 240 });
        });
    }
});