chorus.dialogs.ConfigureWorkfileTask = chorus.dialogs.PickItems.include(chorus.Mixins.DialogFormHelpers).extend({
    constructorName: 'CreateWorkfileTask',
    searchPlaceholderKey: 'job_task.work_flow.search_placeholder',
    modelClass: 'Workfile',
    pagination: true,
    multiSelection: false,
    message: 'create_job_task_dialog.toast',
    title: function () {
        return this.model.isNew() ? t('create_job_task_dialog.add_title') : t('create_job_task_dialog.edit_title');
    },
    submitButtonTranslationKey: function () {
        return this.model.isNew() ? 'create_job_task_dialog.add' : 'create_job_task_dialog.save';
    },

    setup: function() {
        this._super("setup");

        this.job = this.options.job || this.model.job();
        this.workspace = this.job.workspace();

        if (!this.model) {
            this.model = this.model || new chorus.models.JobTask({job: {id: this.job.get("id"), workspace: {id: this.workspace.get("id")}}});
        }

        this.collection = this.options.collection;
        this.pickItemsList.templateName = "workfile_picker_list";
        this.pickItemsList.className = "workfile_picker_list";

        this.disableFormUnlessValid({
            formSelector: "form",
            checkInput: this.isWorkfileSelected
        });

        this.listenTo(this.model, "saved", this.modelSaved);
        this.listenTo(this.model, "saveFailed", this.saveFailed);

        this.collection.fetch();
    },

    collectionModelContext: function (model) {
        return {
            id: model.get("id"),
            name: model.get("fileName"),
            imageUrl: model.iconUrl({size: 'icon'})
        };
    },

    itemSelected: function (workfile) {
        this.selectedWorkfileId = workfile.get("id");
        this.enableOrDisableSubmitButton();
    },

    isWorkfileSelected: function () {
        return !!this.selectedWorkfileId;
    },

    fieldValues: function () {
        return {
            workfileId: this.selectedWorkfileId,
            action: this.action()
        };
    },

    action: function() {
        return this.isSql() ? 'run_sql_workfile' : 'run_work_flow';
    },

    isSql: function () {
        return this.collection && this.collection.attributes.fileType === 'sql';
    },

    submit: function () {
        this.$('form').submit();
    },

    modelSaved: function () {
        chorus.toast(this.message);
        this.model.trigger('invalidated');
        this.job.trigger('invalidated');
        this.closeModal();
    },

    create: function () {
        this.$("button.submit").startLoading('actions.saving');
        this.model.save(this.fieldValues(), {wait: true});
    }
});
