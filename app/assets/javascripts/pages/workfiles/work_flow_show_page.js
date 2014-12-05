chorus.pages.WorkFlowShowPage = chorus.pages.Base.include(
    chorus.Mixins.DataSourceCredentials.page
).extend({
    templateName: "header_iframe_layout",
    additionalClass: "logged_in_layout",
    pageClass: "full_height",

    events: {
        "click a": "preventLinkNavigation",
        "keydown .search input": "preventSearchNavigation"
    },

    makeModel: function(workfileId) {
        this.model = new chorus.models.AlpineWorkfile({id: workfileId});
        this.handleFetchErrorsFor(this.model);
        this.model.urlParams = {connect: true};
        this.model.fetch();
    },

    setup: function() {
        this.listenTo(this.model, "loaded", this.render);
        this.boundIframeListener = _.bind(this.respondToIframe, this);
        window.addEventListener('message', this.boundIframeListener);
        this.preventNavigation();
    },

    teardown: function() {
        this._super("teardown", arguments);
        window.removeEventListener('message', this.boundIframeListener);
    },

    context: function() {
        return {
            alpineUrl: this.model.loaded ? this.model.iframeUrl() : ""
        };
    },

    respondToIframe: function(event) {
        if(event.data.action === 'unauthorized') {
            chorus.requireLogin();
        } else if(event.data.action === 'go_to_workfile') {
            chorus.router.navigate(this.model.showUrl());
        } else if(event.data.action === 'allow_close') {
            chorus.router.navigate(this.intendedHref);
        }
    },

    preventNavigation: function() {
        this.header.disableSearch();
    },

    preventLinkNavigation: function(e) {
        var target = $(e.currentTarget);
        if (target.attr("target") !== "_blank") {
            e.preventDefault();
            this.intendedHref = target.attr("href");
            this.postMessageToIframe({'action': 'intent_to_close'}, '*');
        }
    },

    preventSearchNavigation: function(e) {
        if (e.keyCode === 13) {
            e.preventDefault();

            var searchHref = this.$("li.selected a").attr("href");
            if (searchHref || !chorus.models.Config.instance().license().limitSearch()) {
                this.intendedHref = searchHref || "#/search/" + $(e.currentTarget).val();
                this.postMessageToIframe({'action': 'intent_to_close'}, '*');
            }
        }
    },

    postMessageToIframe: function(message, context) {
        this.iframe().contentWindow.postMessage(message, context);
    },

    iframe: function() {
        return this.$("iframe#alpine")[0];
    }
});
