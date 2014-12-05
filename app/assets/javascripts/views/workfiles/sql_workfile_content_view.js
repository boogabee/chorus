chorus.views.SqlWorkfileContent = chorus.views.Base.extend({
    constructorName: "SqlWorkfileContent",

    templateName: "sql_workfile_content",

    subviews: {
        '.text_content': 'textContent',
        '.results_console': 'resultsConsole'
    },

    hotkeys: {
        'r': 'file:runCurrent',
        'e': 'file:runSelected'
    },

    setup: function() {
        this._super("setup");

        this.textContent = new chorus.views.TextWorkfileContent({ model: this.model, hotkeys: this.hotkeys });
        this.resultsConsole = new chorus.views.ResultsConsole({
            enableResize: true,
            enableExpander: true
        });
        this.subscribePageEvent("file:runCurrent", this.runInDefault);
        this.subscribePageEvent("file:runSelected", this.runSelected);
        this.subscribePageEvent("file:runInSchema", this.runInSchema);
        this.subscribePageEvent("file:newChorusView", this.newChorusView);
        this.subscribePageEvent("file:newSelectionChorusView", this.newSelectionChorusView);
        this.subscribePageEvent("file:runAndDownload", this.runAndDownload);
    },

    runInSchema: function(options) {
        this.run(options);
    },

    runSelected: function() {
        var runOptions = {selection: true};
        var schema = this.model.executionSchema();
        if(schema){
            runOptions.schemaId = schema.get("id");
        }

        this.run(runOptions);
    },

    runInDefault: function(options) {
        options = options || {};
        if (!this.model.executionSchema()) return;
        this.run(_.extend(options, {
            schemaId: this.model.executionSchema().get('id')
        }));
    },

    runAndDownload: function(options) {
        this.runInDefault(_.extend({
            taskClass: chorus.models.SqlExecutionAndDownloadTask
        }, options));
    },

    run: function(options) {
        options = options || {};
        if (this.executing) {
            return;
        }
        if(options.selection) {
            options.selection = this.getSelectedText();
        }

        this.createTask(options.taskClass || chorus.models.WorkfileExecutionTask);

        this.executing = true;
        this.task.set({
            sql: options && options.selection ? options.selection : this.textContent.editor.getValue(),
            workfile: this.model,
            schemaId: options.schemaId,
            checkId: (new Date().getTime().toString()),
            numOfRows: options.numOfRows
        }, { silent: true });

        this.task.save({}, { method: "create" });
        chorus.PageEvents.trigger("file:executionStarted", this.task);
    },

    createTask: function(taskClass) {
        if (this.task) {
            this.stopListening(this.task, 'saved', this.executionSucceeded);
            this.stopListening(this.task, 'saveFailed', this.executionFailed);
        }
        this.task = new taskClass({ });
        this.listenTo(this.task, 'saved', this.executionSucceeded);
        this.listenTo(this.task, 'saveFailed', this.executionFailed);
        this.resultsConsole.setModel(this.task);
    },

    newChorusView: function() {
        return this.newChorusViewWithContent(this.textContent.editor.getValue());
    },

    newSelectionChorusView: function() {
        return this.newChorusViewWithContent(this.getSelectedText());
    },

    newChorusViewWithContent: function(content) {
        var executionSchema = this.model.executionSchema();

        this.chorusView = new chorus.models.ChorusView({
            sourceObjectId: this.model.id,
            sourceObjectType: "workfile",
            workspace: this.model.get("workspace"),
            query: content
        });
        this.chorusView.sourceObject = this.model;
        this.chorusView.setSchema(executionSchema);

        var dialog = new chorus.dialogs.VerifyChorusView({model: this.chorusView});
        dialog.launchModal();
    },

    getSelectedText: function() {
        return this.textContent.editor.getSelection();
    },

    executionSucceeded: function(task) {
        this.executing = false;
        chorus.PageEvents.trigger("file:executionSucceeded", task);
        chorus.PageEvents.trigger("workfile:changed", this.model);
    },

    executionFailed: function(task) {
        this.executing = false;
        chorus.PageEvents.trigger("file:executionFailed", task);
    }
});
