chorus.views.LocationPicker.SelectorView = chorus.views.Base.extend({

    onSelection: $.noop,
    onFetchFailed: $.noop,
    onMissingSelection: $.noop,

    setup: function() {
        this.childPicker = this.options.childPicker;
    },

    maybeHideChildren: function() {
        if (!this.childPicker || this.childPicker.isHidden()) {
            return;
        }
        var waitingForSelect = (this.stateValue === this.STATES.SELECT && !this.selection);
        var notChoosable = _.contains([this.STATES.UNAVAILABLE, this.STATES.LOADING, this.STATES.HIDDEN], this.stateValue);
        if(notChoosable || waitingForSelect) {
            this.childPicker.hide();
        }
    },

    setState: function(stateValue) {
        this.stateValue = stateValue;
        this.restyle(stateValue);
        this.maybeHideChildren();
    },

    hide: function() {
        this.setState(this.STATES.HIDDEN);
    },

    loading: function() {
        this.setState(this.STATES.LOADING);
    },

    unavailable: function() {
        this.setState(this.STATES.UNAVAILABLE);
    },

    selecting: function() {
        this.setState(this.STATES.SELECT);
    },

    createNew: function() {
        this.clearSelection();
        this.setState(this.STATES.CREATE_NEW);
    },

    isHidden: function() {
        return this.stateValue === this.STATES.HIDDEN;
    },

    setSelection: function(model) {
        this.selection = model;
        this.onSelection();
    },

    collectionLoaded: function() {
        if(!this.isHidden()) {
            if (this.collection.length === 0) {
                this.unavailable();
            } else {
                this.selecting();
            }
        }
    },

    postRender: function() {
        this.restyle(this.stateValue);
    },

    modelIsSelected: function(defaultValue, model) {
        var modelIsSelected = defaultValue && model.id === defaultValue.id;
        return modelIsSelected;
    },

    appendModelToSelect: function(select, defaultValue) {
        return _.bind(function(model) {
            var option = $("<option/>")
                .prop("value", model.id)
                .text(Handlebars.Utils.escapeExpression(model.get("name")));
            if(this.modelIsSelected(defaultValue, model)) {
                option.attr("selected", "selected");
            }
            select.append(option);
        }, this);
    },

    selectionIsMissing: function(defaultValue) {
        var selectionIsMissing = (defaultValue !== undefined && !_.contains(_.pluck(this.collection.models, "id"), defaultValue.id));
        return selectionIsMissing;
    },

    populateSelect: function(defaultValue) {
        var select = this.rebuildEmptySelect();

        _.each(this.sortModels(this.collection && this.collection.models), this.appendModelToSelect(select, defaultValue));
        if(this.selectionIsMissing(defaultValue)) {
            this.onMissingSelection();
            this.clearSelection();
        }

        _.defer(function() {
            chorus.styleSelect(select);
        });
    },

    rebuildEmptySelect: function() {
        var select = this.$("select");
        select.html($("<option/>").prop('value', '').text(t("sandbox.select_one")));
        return select;
    },

    sortModels: function(models) {
        return _.clone(models).sort(function(a, b) {
            return naturalSort(a.get("name").toLowerCase(), b.get("name").toLowerCase());
        });
    },

    fetchFailed: function(collection) {
        this.onFetchFailed();
        this.trigger("error", collection);
    },

    restyle: function(state) {
        var section = this.$el;
        section.removeClass("hidden");
        section.find("a.new").removeClass("hidden");
        section.find(".loading_text, .select_container, .create_container, .unavailable").addClass("hidden");
        section.find(".create_container").removeClass("show_cancel_link");

        this.rebuildEmptySelect();

        switch(state) {
        case this.STATES.LOADING:
            section.find(".loading_text").removeClass("hidden");
            break;
        case this.STATES.SELECT:
            section.find(".select_container").removeClass("hidden");
            this.populateSelect(this.selection);
            break;
        case this.STATES.CREATE_NEW:
            section.find(".create_container").removeClass("hidden");
            section.find(".create_container").addClass("show_cancel_link");
            section.find("a.new").addClass("hidden");
            break;
        case this.STATES.CREATE_NESTED:
            section.find(".create_container").removeClass("hidden");
            section.find("a.new").addClass("hidden");
            break;
        case this.STATES.UNAVAILABLE:
            section.find(".unavailable").removeClass("hidden");
            break;
        case this.STATES.HIDDEN:
            section.addClass("hidden");
            break;
        }
    },

    clearSelection: function() {
        delete this.selection;
        this.trigger('change');
    },

    STATES: {
        HIDDEN: 0,
        LOADING: 1,
        SELECT: 2,
        STATIC: 3,
        UNAVAILABLE: 4,
        CREATE_NEW: 5,
        CREATE_NESTED: 6
    }
});