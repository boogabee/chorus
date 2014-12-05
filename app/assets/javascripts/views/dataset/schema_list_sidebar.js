chorus.views.SchemaListSidebar = chorus.views.Sidebar.extend({
    templateName: "schema_list_sidebar",

    additionalContext: function() {
        return {
            sidebarType: this.resource && t("schema_list.sidebar.type." + this.resource.get("entityType"))
        };
    },

    setup: function() {
        this.subscribePageEvent("schema:selected", this.setSchema);
        this.subscribePageEvent("schema:deselected", this.unsetSchema);
    },

    setSchema: function(schema) {
        this.resource = schema;
        this.render();
    },

    unsetSchema: function() {
        delete this.resource;
        this.render();
    }
});
