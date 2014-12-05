chorus.views.SearchResultCommentList = chorus.views.Base.extend({
    constructorName: "SearchResultCommentList",
    templateName: "search_result_comment_list",

    events: {
        "click a.show_more_comments": "showMoreComments",
        "click a.show_fewer_comments": "showFewerComments"
    },

    setup: function() {
        var comments = this.options.comments || [];
        var columns = this.options.columns || [];
        var columnDescriptions = this.options.columnDescriptions || [];
        var tableDescription = this.options.tableDescription || [];

        this.collection = comments.concat(columns).concat(columnDescriptions).concat(tableDescription);
    },

    showMoreComments: function(e) {
        e && e.preventDefault();
        this.$(".has_more_comments").addClass("hidden");
        this.$(".more_comments").removeClass("hidden");
    },

    showFewerComments: function(e) {
        e && e.preventDefault();
        this.$(".has_more_comments").removeClass("hidden");
        this.$(".more_comments").addClass("hidden");
    },

    additionalContext: function() {
        var comments = this.collection || [];
        return {
            comments: comments.slice(0, 3),
            moreComments: comments.slice(3),
            hasMoreComments: Math.max(0, comments.length - 3)
        };
    }
});