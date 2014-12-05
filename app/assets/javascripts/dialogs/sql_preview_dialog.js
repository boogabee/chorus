chorus.dialogs.SqlPreview = chorus.dialogs.Base.extend({
    constructorName: "SqlPreview",

    templateName: "sql_preview",
    title: t("sql_preview.dialog.title"),
    additionalClass: "dialog_wide",

    events: {
        "click .preview" : "previewData",
        "click button.cancel": "cancelTask"
    },

    subviews: {
        ".results_console": "resultsConsole"
    },

    setup: function() {
        this.resultsConsole = new chorus.views.ResultsConsole({
            titleKey: "dataset.data_preview",
            enableExpander: true,
            enableClose: true,
            enableResize: false
        });

        this.subscribePageEvent("action:closePreview", this.hidePreviewData);
        this.subscribePageEvent("modal:closed", this.cancelTask);
    },

    makeCodeMirrorOptions: function() {
        return {
            lineNumbers: true,
            fixedGutter: true,
            theme: "default",
            lineWrapping: true,
            readOnly: "nocursor",
            mode: "text/x-plsql",
            viewportMargin: Infinity
        };
    },

    postRender: function() {
        var textArea = this.$(".text_editor");
        textArea.addClass('hidden');
        _.defer(_.bind(function() {
            this.editor = CodeMirror.fromTextArea(textArea[0], this.makeCodeMirrorOptions());
            this.editor.refresh();
        }, this));
        this.hidePreviewData();
    },

    hidePreviewData: function() {
        this.$(".results_console").addClass("hidden");
        this.$("button.preview").removeClass("invisible");
    },

    previewData: function(e) {
        e && e.preventDefault();
        this.$(".results_console").removeClass("hidden");
        this.$("button.preview").addClass("invisible");
        var preview = this.model.preview().set({ query: this.sql() }, {silent: true});
        this.resultsConsole.execute(preview);
    },

    sql: function() {
        return this.model.get("query");
    },

    cancelTask: function() {
        this.resultsConsole.cancelExecution();
    }
});
