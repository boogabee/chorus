chorus.views.SearchHdfsEntry = chorus.views.SearchItemBase.extend({
    constructorName: "SearchHdfsEntryView",
    templateName: "search_hdfs",

    additionalContext: function() {
        var segments  = this.getHighlightedPathSegments();
        var pathSegments = this.model.pathSegments() || [];
        pathSegments.shift(); // remove root segment
        pathSegments.push(this.model);
        var pathLinks = _.map(pathSegments, function(entry, index) {
            if (this.hasHighlightedAttributes()) {
                var link = $("<a></a>").attr("href", entry.showUrl());
                link.html(segments[index]);
                return new Handlebars.SafeString(link.outerHtml());
            } else {
                return Handlebars.helpers.linkTo(entry.showUrl(), entry.get("name"));
            }
        }, this);
        var hdfsDataSource = this.model.getHdfsDataSource();

        return _.extend(this._super("additionalContext"), {
            showUrl: this.model.showUrl(),
            humanSize: I18n.toHumanSize(this.model.get("size")),
            iconUrl: chorus.urlHelpers.fileIconUrl(_.last(this.model.get("name").split("."))),
            dataSourceLink: Handlebars.helpers.linkTo(hdfsDataSource.showUrl(), hdfsDataSource.get('name')),
            completePath: new Handlebars.SafeString(pathLinks.join(" / ")),
            displayableFiletype: this.model.get('isBinary') === false
        });
    },

    getHighlightedPathSegments: function() {
        var path = this.hasHighlightedAttributes(this.model) ? this.model.get("highlightedAttributes")["path"][0] : this.model.get("path");
        return path.split(/\/(?!em>)/).slice(1);
    },

    hasHighlightedAttributes: function() {
        return this.model.get("highlightedAttributes") && this.model.get("highlightedAttributes")["path"];
    }
});
