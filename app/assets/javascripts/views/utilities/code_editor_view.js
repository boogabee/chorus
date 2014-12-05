chorus.views.CodeEditorView = chorus.views.Base.extend({
    templateName: "code_editor_view",
    constructorName: 'CodeEditorView',

    setup: function(options) {
        this.options = _.extend({
            lineNumbers: true,
            fixedGutter: true,
            styleActiveLine: true,
            theme: "default",
            lineWrapping: true,
            matchBrackets: true,
            onBlur: _.bind(this.onBlur, this),
            onChange: _.bind(this.onChange, this),
            onCursorActivity: $.noop,
            viewportMargin: Infinity
        }, options);
    },

    teardown: function () {
        if (this.editor) {
            if (this.$('.CodeMirror').data('droppable')) {
                this.$('.CodeMirror').droppable("destroy");
            }
            this.$('.CodeMirror').off();
            this.$('.CodeMirror *').off();
            if (this.editor.getWrapperElement) {
                delete this.editor.getWrapperElement().CodeMirror;
            }
            this.editor.toTextArea();
        }
        this.$('textarea').unbind();

        delete this.options.onBlur;
        delete this.options.onChange;
        delete this.options.onCursorActivity;
        delete this.editor;
        delete this.textArea;

        this._super('teardown', [true]);
    },

    setupCodeMirror: function() {
        if(!this.torndown) {
            var textArea = this.$(".text_editor")[0];
            if(textArea !== this.textArea) {
                this.textArea = textArea;
                var editor = this.editor = CodeMirror.fromTextArea(this.textArea, this.options);
                editor.on('change', this.options.onChange);
                editor.on('blur', this.options.onBlur);
                editor.on('cursorActivity', this.options.onCursorActivity);
                _.defer(function() {
                    editor.refresh();
                });
                if(this.options.beforeEdit) {
                    this.options.beforeEdit.call(this);
                }
                this.$(".CodeMirror").droppable({
                    drop: _.bind(this.acceptDrop, this),
                    out: _.bind(this.endDragging, this),
                    over: _.bind(this.startDragging, this),
                    tolerance: 'pointer'
                });
            }
        }
    },

    postRender: function() {
        _.defer(_.bind(this.setupCodeMirror, this));
        this.$dropInsertionPoint = $('.drop_insertion_point');
        this.$noCursorOverlay = $('.no_cursor_overlay');
    },

    repositionInsertionPoint: function(event) {
        var characterPosition = this.editor.coordsChar({left: event.pageX, top: event.pageY });
        var pixelPosition = this.editor.charCoords(characterPosition);
        this.$dropInsertionPoint.css("left", pixelPosition.left);
        this.$dropInsertionPoint.css("top", pixelPosition.top);
        this.editor.setCursor(characterPosition);
    },

    startDragging: function() {
        this.$noCursorOverlay.show();
        this.$noCursorOverlay.bind("mousemove.drop_insertion_point", _.bind(this.repositionInsertionPoint, this));
        this.$dropInsertionPoint.show();
    },

    endDragging: function() {
        this.$noCursorOverlay.hide();
        this.$dropInsertionPoint.hide();
    },

    acceptDrop: function(e, ui) {
        this.endDragging();
        var pos = this.editor.coordsChar({left: e.pageX, top: e.pageY});
        this.editor.setCursor(pos);
        this.insertText(ui.draggable.data("fullname"));
    },

    insertText: function(text) {
        this.editor.focus();
        this.editor.replaceSelection(text);
        this.editor.setCursor(this.editor.getCursor(false));
    },

    onBlur: function () {
        this.trigger('blur');
    },

    onChange: function () {
        this.trigger('change');
    },

    additionalContext: function() {
        return { editorContent: this.model.content() };
    }
});

// delegate methods to the CodeMirror editor
_.each([
    'getValue', 'setValue', 'getOption', 'setOption', 'getSelection',
    'setSelection', 'focus', 'getCursor', 'setCursor', 'lineCount', 'getLine'
], function(method) {
    chorus.views.CodeEditorView.prototype[method] = function() {
        return this.editor && this.editor[method].apply(this.editor, arguments);
    };
});
