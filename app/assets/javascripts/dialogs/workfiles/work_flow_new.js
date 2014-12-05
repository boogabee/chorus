//= require ./work_flow_new_base_dialog

chorus.dialogs.WorkFlowNew = chorus.dialogs.WorkFlowNewBase.extend({
    constructorName: 'WorkFlowNewDialog',
    additionalClass: 'dialog_wide',

    subviews: {
        ".database_picker": "executionLocationList"
    },

    userWillPickSchema: true,

    setupSubviews: function(){
        var sandbox = this.options.pageModel.sandbox();
        this.executionLocationList = new chorus.views.WorkFlowExecutionLocationPickerList({
            dataSource: sandbox && sandbox.database().dataSource(),
            database: sandbox && sandbox.database()
        });
        this.listenTo(this.executionLocationList, "change", this.toggleSubmitDisabled);
    },

    checkInput: function() {
        return this.getFileName().trim().length > 0 && !!this.executionLocationList.ready();
    },

    resourceAttributes: function () {
        return {
            executionLocations: this.executionLocationList.getSelectedLocationParams(),
            fileName: this.getFileName()
        };
    }
});