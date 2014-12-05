chorus.views.DatasetStatistics = chorus.views.Base.extend({
    templateName: "dataset_statistics",

    setup: function(options) {
        this.column = options.column;

        this.statistics = this.model.statistics();
        if (!this.model.get('stale')) {
            this.statistics.fetchIfNotLoaded();
            this.listenTo(this.statistics, "loaded", this.render);
            this.listenTo(this.model, "invalidated", function () { this.statistics.fetch(); });
        }
    },

    context: function() {
        var ctx = {
            column: this.column && this.column.attributes
        };

        ctx.objectName = this.model.get("objectName");
        ctx.typeString = Handlebars.helpers.humanizedDatasetType(this.model && this.model.attributes, this.model.statistics());

        if (!this.statistics) { return ctx; }

        ctx.statistics = this.statistics.attributes;
        if (ctx.statistics.rows === 0) {
            ctx.statistics.rows = "0";
        }

        if (ctx.statistics.partitions > 0) {
            delete ctx.statistics.rows;
        }

        if (ctx.statistics.columns === 0) {
            ctx.statistics.columns = "0";
        }

        ctx.statistics.formattedDiskSize = I18n.toHumanSize(this.statistics.get("onDiskSize"), {precision: 0, format: "%n %u"});

        return ctx;
    }
});
