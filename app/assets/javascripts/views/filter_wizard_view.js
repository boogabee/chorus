chorus.views.FilterWizard = chorus.views.Base.extend({
    templateName: "filter_wizard",
    constructorName: "FilterWizard",
    persistent: true,

    events: {
        "click .add_filter": "addFilter"
    },

    setup: function() {
        this.options = this.options || {};
        this.columnSet = this.options.columnSet;
        this.collection = this.collection || this.filterCollection();
        this.listenTo(this.columnSet, 'remove', this.removeInvalidFilters);
    },

    additionalContext: function() {
        return {
            title: t(this.title),
            extraContent: this.extraContent()
        };
    },

    postRender: function() {
        _.each(this.filterViews, function(filterView) {
            this.stopListening(filterView);
            filterView.teardown();
        }, this);
        this.filterViews = [];
        if (!this.collection.length) {
            this.addFilter();
        } else {
            this.collection.each(function(filter) {
                this.renderFilterView(filter);
            }, this);
        }

        this.tagLastLi();
    },

    resetFilters: function() {
        this.collection.reset();
        this.render();
    },

    renderFilterView: function(filter) {
        var $ul = this.$(".filters");
        var filterView = this.filterView(filter);
        $ul.append(filterView.render().el);
        this.listenTo(filterView, "deleted", function() {this.removeFilterView(filterView);});
        this.filterViews.push(filterView);
        this.registerSubView(filterView);
    },

    addFilter: function(e) {
        e && e.preventDefault();
        this.collection.add(this.filterModel());
        this.renderFilterView(this.collection.last());
        this.tagLastLi();
    },

    removeFilterView: function(filterView) {
        this.collection.remove(filterView.model);
        filterView.teardown();
        this.tagLastLi();
    },

    removeInvalidFilters: function() {
        var badFilters = this.collection.filter(function(filter) {
            return !this.columnSet.include(filter.get("column"));
        }, this);

        if(badFilters) {
            this.collection.remove(badFilters);
            this.render();
        }
    },

    tagLastLi: function() {
        var $ul = this.$(".filters");
        $ul.find("li").removeClass("last");
        $ul.find("li:last-child").addClass("last");
    },

    filterCount: function() {
        return this.collection.count();
    },

    extraContent: function () {
        return '';
    }
});
