chorus.dialogs.ConfigureMilestone = chorus.dialogs.Base.include(chorus.Mixins.DialogFormHelpers).extend({
    constructorName: 'ConfigureMilestoneDialog',
    templateName: 'configure_milestone_dialog',

    title: function () {
        return this.model.isNew() ? t('milestone.dialog.title') : t('milestone.dialog.edit.title');
    },

    message: 'milestone.dialog.toast',

    submitTranslation: function () {
        return this.model.isNew() ? "milestone.dialog.submit" : "milestone.dialog.edit.submit";
    },

    subviews: {
        ".target_date": "targetDatePicker"
    },

    getModel: function () {
        return this.originalModel || this.model;
    },

    makeModel: function () {
        if (this.model) {
            this.originalModel = this.model;
            this.model = this.model.clone();
        }
        this.creating = !this.model;
        this.model = this.model || new chorus.models.Milestone({ workspace: {id: this.options.pageModel.id} });
    },

    create: function () {
        this.$("button.submit").startLoading('actions.saving');
        this.getModel().save(this.fieldValues(), {wait: true, unprocessableEntity: $.noop});
    },

    checkInput: function () {
        var fieldValues = this.fieldValues();
        if (!fieldValues.name || fieldValues.name.length === 0) { return false; }
        if (!this.targetDatePicker.getDate().isValid()) { return false; }

        return true;
    },

    fieldValues: function () {
        return {
            name: this.$('input.name').val(),
            targetDate: this.targetDatePicker.getDate().toISOString()
        };
    },

    modelSaved: function () {
        chorus.toast(this.message);
        chorus.page.collection.trigger('invalidated');
        this.closeModal();
    },

    setup: function () {
        this.targetDatePicker = new chorus.views.DatePicker({date: moment(), selector: 'target_date'});

        this.disableFormUnlessValid({
            formSelector: "form",
            inputSelector: "input",
            checkInput: _.bind(this.checkInput, this)
        });

        this.listenTo(this.getModel(), "saved", this.modelSaved);
        this.listenTo(this.getModel(), 'saveFailed', this.saveFailed);
    },

    additionalContext: function () {
        return { submitTranslation: this.submitTranslation() };
    }
});
