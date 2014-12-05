chorus.views.LocationPicker.BaseView = chorus.views.Base.extend({
    setup: function() {
        this.buildSelectorViews();
        this.bindToSelectorViews();
        this.setSelectorViewDefaults();
    },

    bindSubviewEvents: function(subview) {
        this.listenTo(subview, 'change', this.triggerSchemaSelected);
        this.listenTo(subview, 'error', function(collection) {
            this.trigger('error', collection);
        });
        this.listenTo(subview, 'clearErrors', function() {
            this.trigger('clearErrors');
        });
    },

    bindToSelectorViews: function() {
        _(this.getSubViews()).each(this.bindSubviewEvents, this);
    },

    setSelection: function(type, value) {
        this.getPickerSubview(type).setSelection(value);
        this.triggerSchemaSelected();
    },

    triggerSchemaSelected: function() {
        this.trigger("change", this.ready());
    },

    getPickerSubview: function(type) {
        return this[type + "View"];
    },

    fieldValues: function() {
        var attrs = {};
        var subviewFieldValues = _(this.getSubViews()).invoke('fieldValues');
        _(subviewFieldValues).each(function(fieldValues) {
            _(attrs).extend(fieldValues);
        });
        return attrs;
    },

    ready: function() {
        var readiness = _(this.getSubViews()).invoke('ready');
        return _.all(readiness, _.identity);
    }
});