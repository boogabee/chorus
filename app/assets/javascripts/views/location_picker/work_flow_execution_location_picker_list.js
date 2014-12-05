chorus.views.WorkFlowExecutionLocationPickerList = chorus.views.Base.extend({
    constructorName: 'WorkFlowExecutionLocationPickerList',
    templateName: "execution_location_picker_list",

    events: {
        'click a.add_source': 'addSource'
    },

    setup: function () {
        this.pickers = [];
        var pickerOptions = this.options.pickerOptionSet ? this.options.pickerOptionSet : [_.extend({hideRemoveLink: true}, this.options)];

        _.each(pickerOptions, function (pickerOption) {
            var picker = new chorus.views.WorkFlowExecutionLocationPicker(pickerOption);
            this.addPicker(picker);
        }, this);
    },

    postRender: function() {
        _.each(this.pickers, function(view) {
            this.$el.append(view.render().el);
        }, this);
    },

    ready: function () {
        if (this.pickers.length === 0) { return false; }

        return _.every(this.pickers, function (picker) {
            return picker.ready();
        }, this);
    },

    getSelectedLocations: function () {
        return _.compact(_.invoke(this.pickers, 'getSelectedLocation'));
    },

    getSelectedLocationParams: function () {
        return _.map(this.getSelectedLocations(), function (dataSource) {
            return {
                id: dataSource.id,
                entity_type: dataSource.get('entityType')
            };
        });
    },

    addPicker: function (picker) {
        this.registerSubView(picker);
        this.listenTo(picker, 'change', function () { this.trigger('change'); });
        this.listenTo(picker, 'remove', this.removeSource);
        this.pickers.push(picker);
    },
    
    addSource: function (e) {
        e && e.preventDefault();
        var newPicker = new chorus.views.WorkFlowExecutionLocationPicker();
        this.addPicker(newPicker);
        this.$el.append(newPicker.render().el);
    },

    removeSource: function (picker) {
        this.pickers = _.reject(this.pickers, function (listedPicker) {
            return listedPicker === picker;
        });
        this.trigger('change');
    }
});