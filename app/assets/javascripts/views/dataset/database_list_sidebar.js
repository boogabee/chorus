chorus.views.DatabaseListSidebar = chorus.views.Sidebar.extend({
    templateName: "database_list_sidebar",

    setup: function() {
        this.subscribePageEvent("database:selected", this.setDatabase);
        this.subscribePageEvent("database:deselected", this.unsetDatabase);
    },

    setDatabase: function(database) {
        this.resource = database;
        this.render();
    },

    unsetDatabase: function() {
        delete this.resource;
        this.render();
    },

    additionalContext: function() {
        return this.resource ? { type: "database_list.sidebar." + this.resource.get("entityType") } : {};
    }
});
