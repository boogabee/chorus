chorus.views.ListHeaderView = chorus.views.Base.extend({
    templateName: "default_content_header",

    context: function() {
        var ctx = this.options;
        return _.extend({}, ctx, this.additionalContext());
    },

    postRender: function() {
        var self = this;
        if (this.options.linkMenus) {
            _.each(this.options.linkMenus, function(menuOptions, menuKey) {
                var menu = new chorus.views.LinkMenu(menuOptions);
                self.$(".menus").append(
                    menu.render().el
                );
                $(menu.el).addClass(menuKey);
                menu.bind("choice", function(eventType, choice) {
                    self.trigger("choice:" + eventType, choice);
                });
            });
        }
    }
});
