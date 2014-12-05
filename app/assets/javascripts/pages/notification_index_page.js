chorus.pages.NotificationIndexPage = chorus.pages.Base.extend({
    constructorName: "NotificationIndexPage",
    crumbs: [
        { label: t("breadcrumbs.home"), url: "#/" },
        { label: t("breadcrumbs.notifications") }
    ],

    setup: function() {
        this.collection = new chorus.collections.NotificationSet([]);
        this.listenTo(this.collection, "loaded", this.notificationsFetched);
        this.collection.fetch();

        this.subscribePageEvent("notification:deleted", this.refreshNotifications);

        this.mainContent = new chorus.views.MainContentView({
            collection: this.collection,
            contentHeader: new chorus.views.StaticTemplate("default_content_header", {title:t("header.your_notifications")}),
            content: new chorus.views.NotificationList({ collection: this.collection, allowMoreLink: true })
        });
    },

    notificationsFetched: function() {
        this.collection.markAllRead({});
        this.render();
    },

    refreshNotifications: function() {
        this.collection.fetch();
    }
});