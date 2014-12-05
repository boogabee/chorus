chorus.views.ItemWrapper = chorus.views.Base.extend({
    templateName: 'item_wrapper',
    tagName: "li",

    subviews: {
        '.item_content': 'itemView'
    },

    setup: function() {
        this.itemView = this.options.itemView;
    },

    additionalContext: function() {
        return _.extend({checkable: true}, this.itemView.additionalContext());
    }
});