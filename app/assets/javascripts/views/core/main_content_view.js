chorus.views.MainContentView = chorus.views.Base.extend({
    constructorName: "MainContentView",
    templateName: "main_content",

    setup: function(options) {
        options = options || {};
        this.contentHeader = this.contentHeader || options.contentHeader;
        this.contentDetails = this.contentDetails || options.contentDetails;
        this.content = this.content || options.content;
        this.contentFooter = this.contentFooter || options.contentFooter;
    },

    subviews: {
        ".content_header > div": "contentHeader",
        ".content_details": "contentDetails",
        ".content > div": "content",
        ".content_footer > div": "contentFooter"
    },

    postRender: function() {
        if (!this.contentDetails) this.$(".content_details").addClass("hidden");
        if (!this.content)        this.$(".content").addClass("hidden");
        if (!this.contentFooter)  this.$(".content_footer").addClass("hidden");
    }
});