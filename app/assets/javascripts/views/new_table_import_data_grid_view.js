chorus.views.NewTableImportDataGrid = chorus.views.ImportDataGrid.extend({
    constructorName: "NewTableImportDataGrid",
    headerRowHeight: 16,

    setup: function() {
        this.subscribePageEvent("choice:setType", this.onSelectType);
    },

    customizeHeaderRows: function(columns, columnNames) {
        this.addNameInputsToTopRow(columnNames);
        this.setupDataTypeMenus(columns);
    },

    addNameInputsToTopRow: function(columnNames) {
        _.each(this.$(".slick-header-column"), function (column, index) {
            var $name = $(column).find(".slick-column-name");
            $name.html("<input value='" + columnNames[index] + "'></input>");
        }, this);
    },

    setupDataTypeMenus: function(columns) {
        this.linkMenus = _.map(columns, function(item) {
            var types = ["integer", "double precision", "text", "date", "time", "timestamp"];

            return new chorus.views.LinkMenu({
                options: _.map(types, function(type){ return {data: _.underscored(type), text: type}; }),
                title: '',
                event: "setType",
                chosen: item.type
            });
        });

        var $dataTypes = this.$(".slick-headerrow-columns");
        _.each(this.linkMenus, function(linkMenu, index) {
            var $column = $dataTypes.find(".slick-headerrow-column").eq(index);
            $column.append('<div class="arrow"></div>');
            $column.append(linkMenu.render().el);
            $column.addClass("type");
            $column.addClass(linkMenu.options.chosen);
        });
    },

    onSelectType: function(data, linkMenu) {
        var $typeDiv = $(linkMenu.el).closest("div.type");
        $typeDiv.removeClass("integer float text date time timestamp").addClass(data);
    },

    getColumnNames: function() {
        var $names =  this.$(".column_name input:text");
        var columnNames = _.map($names, function(name, i) {
            return $names.eq(i).val();
        });
        return columnNames;
    },

    getColumnTypes: function() {
        var $types = this.$(".slick-headerrow-columns .chosen");
        var types = _.map($types, function($type, i) {
            return $types.eq(i).text();
        });
        return types;
    },

    markColumnNameInputAsInvalid: function(index) {
        this.markInputAsInvalid(this.$(".column_name input").eq(index), t("import.validation.column_name"), true);
    }
});