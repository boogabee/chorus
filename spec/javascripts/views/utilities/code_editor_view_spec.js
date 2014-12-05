describe("chorus.views.CodeEditorView", function() {
    beforeEach(function() {
        this.workfile = new chorus.models.Workfile();
        spyOn(this.workfile, "content").andReturn("");
        spyOn($.fn, "droppable").andCallThrough();

        this.view = new chorus.views.CodeEditorView({
            model: this.workfile,
            lineWrapping: false
        });
        $("#jasmine_content").append(this.view.el);
        this.clock = this.useFakeTimers();

        // in IE8, we can't 'select' a textrange whose textarea is not on the DOM
        if ($.browser.msie) {
            spyOn(window.TextRange.prototype, 'select');
        }
        spyOn(CodeMirror, "fromTextArea").andCallThrough();
    });

    it("defers call to CodeMirror", function() {
        unstubDelay();
        this.view.render();
        expect(CodeMirror.fromTextArea).not.toHaveBeenCalled();
        this.clock.tick(1000);
        expect(CodeMirror.fromTextArea).toHaveBeenCalled();
    });

    describe("#postRender", function() {
        it("only sets up draggable once", function() {
            this.view.render();
            this.view.postRender();
            expect($.fn.droppable.calls.count()).toEqual(1);
        });
    });

    describe("#render", function() {
        beforeEach(function() {
            this.view.render();
        });

        context("when CodeMirror setup happens twice in one dom render", function() {
            beforeEach(function() {
                this.view.setupCodeMirror();
            });

            it("only creates CodeMirror once", function() {
                expect(CodeMirror.fromTextArea.calls.count()).toBe(1);
            });
        });

        it("displays line numbers", function() {
            expect(this.view.editor.getOption("lineNumbers")).toBe(true);
        });

        it("prepares the editor for drag/drop events", function() {
            expect($($.fn.droppable.nthCall(0).object)[0]).toBe(this.view.$(".CodeMirror")[0]);
        });
    });

    describe("dragging a dataset, column, or function", function() {
        beforeEach(function() {
            this.view.render();
            this.drag = {draggable: $('<div data-fullname="test"></div>')};
            this.view.editor.replaceSelection("this is the first line\n\nthis is the third line");
            expect(this.view.editor.lineCount()).toBe(3);
        });

        describe("repositioning the insertion reticle", function() {
            beforeEach(function() {
                this.mouseMoveEvent = {pageX: -1, pageY: -1};
                this.characterPosition = {line: 2, ch: 12};
                this.pixelPosition = {left: 12, top: 34};
                spyOn(this.view.editor, "coordsChar").andReturn(this.characterPosition);
                spyOn(this.view.editor, "charCoords").andReturn(this.pixelPosition);
            });

            it("computes the insertion point's pixel position based on the character position where text will be inserted", function() {
                this.view.repositionInsertionPoint(this.mouseMoveEvent);
                var pixelPositionParameters = this.view.editor.charCoords.nthCall(0).args[0];
                expect(pixelPositionParameters).toBe(this.characterPosition);
            });

            it("updates the position of the insertion point", function(){
                this.view.repositionInsertionPoint(this.mouseMoveEvent);

                var $reticle = this.view.$dropInsertionPoint;
                expect($reticle.css("left")).toBe(this.pixelPosition.left + "px");
                expect($reticle.css("top")).toBe(this.pixelPosition.top + "px");
            });
        });

        describe("starting dragging", function() {
            it("shows the no cursor overlay", function() {
                expect(this.view.$('.no_cursor_overlay')).toBeHidden();
                this.view.startDragging();
                expect(this.view.$('.no_cursor_overlay')).not.toBeHidden();
            });

            it("shows the insertion point", function() {
                expect(this.view.$dropInsertionPoint).toBeHidden();
                this.view.startDragging();
                expect(this.view.$dropInsertionPoint).not.toBeHidden();
            });

            it("repositions the insertion point when the mouse is moved", function() {
                spyOn(this.view, 'repositionInsertionPoint');
                this.view.startDragging();
                $(".no_cursor_overlay").trigger('mousemove');
                expect(this.view.repositionInsertionPoint).toHaveBeenCalled();
            });
        });
    });

    describe("dropping a dataset, column, or function", function() {
        beforeEach(function() {
            this.view.render();
            this.drag = {draggable: $('<div data-fullname="+++"></div>')};
            this.view.editor.replaceSelection("this is the first line\n\nthis is the third line");
            expect(this.view.editor.lineCount()).toBe(3);
            this.view.startDragging();
        });

        it("inserts text at the beginning of a line", function() {
            // Shift coordinates a little bit so we aren't right on a line boundary
            // This was causing different behavior between Chrome, Firefox, and Phantom
            var pixelPosition = this.view.editor.charCoords({line: 2, ch: 0});
            var event = { pageX: pixelPosition.left, pageY: pixelPosition.top-1};
            this.view.acceptDrop(event, this.drag);
            expect(this.view.editor.getLine(1)).toBe("+++");
        });

        it("inserts text in the middle of a line", function() {
            var pos = this.view.editor.charCoords({line: 2, ch: 12});
            this.view.acceptDrop({pageX: pos.left, pageY: pos.top}, this.drag);
            expect(this.view.editor.getLine(2)).toBe("this is the +++third line");
        });

        it('cancels all the dragging behavior', function(){
            var pos = this.view.editor.charCoords({line: -1, ch: -1});
            this.view.acceptDrop({pageX: pos.left, pageY: pos.top}, this.drag);
            expect(this.view.$('.no_cursor_overlay')).toBeHidden();
            expect(this.view.$dropInsertionPoint).toBeHidden();
        });
    });

    describe("delegation", function() {
        beforeEach(function() {
            this.view.render();
        });

        it("delegates a method to editor", function() {
            spyOn(this.view.editor, 'getValue').andReturn("Some value");
            expect(this.view.getValue()).toBe("Some value");
        });
    });
});
