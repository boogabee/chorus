//= require ./workfile_sidebar
chorus.views.AlpineWorkfileSidebar = chorus.views.WorkfileSidebar.extend({
    setup: function() {
        this.options.showVersions = false;
        this.options.showDownloadLink = false;
        this.options.showUpdatedTime = false;
        this._super('setup', arguments);
    }
});