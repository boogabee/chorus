chorus.Mixins.BoundForMultiSelect = {
    preInitialize: function () {
        this.events["change .select_all"] = "changeSelection";
        this.subscribePageEvent("noneSelected", this.allUnselected);
        this.subscribePageEvent("unselectAny", this.anyUnselected);
        this.subscribePageEvent("allSelected", this.allSelected);
        this.selectAllChecked = false;
        this._super("preInitialize", arguments);
    },

    changeSelection: function(e) {
        e.preventDefault();
        if ($(e.currentTarget).is(":checked")) {
            chorus.PageEvents.trigger("selectAll");
            this.selectAllChecked = true;
        } else {
            chorus.PageEvents.trigger("selectNone");
            this.selectAllChecked = false;
        }
    },

    renderCheckedState: function () {
        this.$(".select_all").prop("checked", this.selectAllChecked);
    },

    allSelected: function () {
        this.$(".select_all").prop("checked", true);
        this.$(".select_all").prop("indeterminate", false);
        this.selectAllChecked = true;
    },

    anyUnselected: function () {
        this.$(".select_all").prop("checked", true);
        this.$(".select_all").prop("indeterminate", true);
        this.selectAllChecked = true;
    },

    allUnselected: function () {
        this.$(".select_all").prop("checked", false);
        this.$(".select_all").prop("indeterminate", false);
        this.selectAllChecked = false;
    },

    unselectOnFetch: function() {
        var selectNone = function() {
            chorus.PageEvents.trigger('selectNone');
        };
        this.subscribePageEvent("choice:filter", selectNone);
        this.subscribePageEvent("choice:sort", selectNone);
        this.listenTo(this.collection, 'paginate searched', selectNone);
    }
};