chorus.views.ImportDataGrid = chorus.views.Base.extend({
    templateName: "import_data_grid",
    constructorName: "ImportDataGrid",
    additionalClass: "import_data_grid",
    headerRowHeight: 0,
    columnStartingWidth: 100,
    customizeHeaderRows: $.noop,
    events: { "click .slick-cell": "selectCell" },

    initializeDataGrid: function(columns, rows, columnNames) {
        if(!this.inDocument()) { return; }
        var gridCompatibleRows = this.convert2DArrayToArrayOfHashTables(rows);
        var gridCompatibleColumnCells = _.map(columns, function (column, index) {
            return {
                name: column.name,
                field: index.toString(),
                id: index.toString(),
                minWidth: this.columnStartingWidth
            };
        }, this);

        this.grid && this.grid.destroy();
        this.grid = new Slick.Grid(this.$(".grid"), gridCompatibleRows, gridCompatibleColumnCells, this._slickGridOptions(columns));
        this.scrollHeaderRow();
        this.customizeHeaderRows(columns, columnNames);
        this.$(".slick-column-name").addClass("column_name");

        _.defer(_.bind(this.resizeGridToResultsConsole, this));
    },

    inDocument: function () {
        return (this.$el.closest('body').length > 0);
    },

    resizeGridToResultsConsole: function() {
        if(!this.inDocument()) { return; }
        this.grid.resizeCanvas();
        this.grid.invalidate();
    },
    scrollHeaderRow: function() {
        this.grid.onScroll.subscribe(_.bind(function (e, args) {
            this.$('.slick-headerrow-columns').css({left: -args.scrollLeft});
        }, this));
    },

    convert2DArrayToArrayOfHashTables: function(rows) {
        return _.map(rows, function (row) {
            return _.reduce(row, function (memo, cell, index) {
                memo[index.toString()] = cell;
                return memo;
            }, {});
        });
    },

    cellFormatter: function(row, cell, value, columnDef, dataContext){
        if (!value) { return value; }

        return "<span title='"+value+"'>"+value+"</span>";
    },

    selectCell: function(e) {
        if (window.getSelection && document.createRange) {
            var sel = window.getSelection();
            var range = document.createRange();
            range.selectNodeContents(e.currentTarget);
            sel.removeAllRanges();
            sel.addRange(range);
        } else if (document.selection && document.body.createTextRange) {
            var textRange = document.body.createTextRange();
            textRange.moveToElementText(e.currentTarget);
            textRange.select();
        }
    },

    teardown: function() {
        this.grid && this.grid.destroy();
        this._super("teardown");
    },

    forceFitColumns: function (columns) {
        return (columns.length * this.columnStartingWidth) <= this.$el.width();
    },

    _slickGridOptions: function(columns) {
        return {
            defaultColumnWidth: 130,
            defaultFormatter: this.cellFormatter,
            enableCellNavigation: false,
            enableColumnReorder: false,
            enableTextSelectionOnCells: true,
            forceFitColumns: this.forceFitColumns(columns),
            headerRowHeight: this.headerRowHeight,
            showHeaderRow: true,
            syncColumnCellResize: true
        };
    }
});