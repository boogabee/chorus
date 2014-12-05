chorus.dialogs.DatasetsPicker = chorus.dialogs.PickItems.extend({
    title: t("dataset.pick_destination"),
    constructorName: "DatasetsPickerDialog",
    additionalClass: "with_sub_header pick_dataset_with_action",
    submitButtonTranslationKey: "actions.dataset_select",
    emptyListTranslationKey: "dataset.none",
    searchPlaceholderKey: "dataset.dialog.search_table",
    selectedEvent: 'datasets:selected',
    modelClass: "Table",
    pagination: true,
    multiSelection: false,

    events: _.extend({
        "click a.preview_columns": "clickPreviewColumns"
    }, this.events),

    setup: function() {
        this._super("setup");
        this.title = this.options.title || this.title;
        this.pickItemsList.templateName = "datasets_picker_list";
        this.pickItemsList.className = "datasets_picker_list";
        this.collection.sortAsc("objectName");
        this.collection.fetch();
    },

    collectionModelContext: function (model) {
        return {
            id: model.get("id"),
            name: model.get("objectName"),
            imageUrl: model.iconUrl({size: 'icon'})
        };
    },

    clickPreviewColumns: function(e) {
        e && e.preventDefault();

        var clickedId = $(e.target).closest("li").data("id");
        var dataset = this.collection.get(clickedId);

        var previewColumnsDialog = new chorus.dialogs.PreviewColumns({model: dataset});
        previewColumnsDialog.title = this.title;
        this.launchSubModal(previewColumnsDialog);
    },

    modalClosed: function() {
        this._super("modalClosed", arguments);
        this.collection.search("");
    }
});
