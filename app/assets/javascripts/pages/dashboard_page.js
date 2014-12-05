chorus.pages.DashboardPage = chorus.pages.Base.extend({
    constructorName: "DashboardPage",
    hasSubHeader: true,

    setup: function() {
        this.mainContent = new chorus.views.ModularDashboard({});
        this.mainContent.additionalClass = "main_content";
    },

    setupSubHeader: function() {
        var model = new chorus.models.Base({name: t("header.home")});
        var klazz = chorus.views.SubHeader.extend({
            templateName: "dashboard/sub_header",
            additionalContext: function() {
                return { editUrl: "#/users/" + chorus.session.user().id + "/dashboard_edit" };
            }
        });
        this.subHeader = new klazz({model: model});
    }
});
