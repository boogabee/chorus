chorus.dialogs.ChangeWorkFlowExecutionLocation = chorus.dialogs.Base.extend({
    templateName:"change_work_flow_execution_location",
    title: t("work_flows.change_execution_location.title"),
    constructorName: "ChangeWorkFlowExecutionLocation",
    additionalClass: 'dialog_wide',

    subviews: {
        ".location_picker": "executionLocationList"
    },

    events: {
        "click button.submit": "save"
    },

    setup: function() {
        // this.model is the workfile (work flow)
        this.listenTo(this.model, "saved", this.saved);
        this.listenTo(this.model, "saveFailed", this.saveFailed);

        var options = _.map(this.model.executionLocations(), function (location) {
            if (location.dataSource) {
                return {
                    database: location,
                    dataSource: location.dataSource()
                };
            } else {
                return { dataSource: location };
            }
        });

        this.executionLocationList = new chorus.views.WorkFlowExecutionLocationPickerList({pickerOptionSet: options});

        this.listenTo(this.executionLocationList, "change", this.enableOrDisableSubmitButton);
        this.listenTo(this.executionLocationList, "error", this.showErrors);
        this.listenTo(this.executionLocationList, "clearErrors", this.clearErrors);
    },

    save: function(e) {
        e.preventDefault();

        this.model.unset("database_id");
        this.model.unset("hdfs_data_source_id");
        this.model.save({execution_locations: this.executionLocationList.getSelectedLocationParams()});
        this.$("button.submit").startLoading("actions.saving");
        this.$("button.cancel").prop("disabled", true);
    },

    saved: function() {
        this.closeModal();
    },

    saveFailed: function() {
        this.showErrors(this.model);
    },

    enableOrDisableSubmitButton: function() {
        this.$("button.submit").prop("disabled", !this.executionLocationList.ready());
    },

    postRender: function () {
        this.enableOrDisableSubmitButton();
    }
});