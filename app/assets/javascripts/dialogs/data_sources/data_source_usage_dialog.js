chorus.dialogs.DataSourceUsage = chorus.dialogs.Base.extend({
    constructorName: "DataSourceUsage",

    templateName: "data_source_usage",
    title: t("data_sources.usage.title"),
    useLoadingSection: true,
    additionalClass: 'with_sub_header',

    setup: function() {
        this.dataSource = this.options.dataSource;
        this.usage = this.resource = this.dataSource.usage();
        this.usage.fetchIfNotLoaded();
        this.requiredResources.push(this.usage);
    },

    additionalContext: function(context) {
        var online = this.dataSource.get("state") !== 'offline';
        _.each(context.workspaces, function(workspace) {
            if(online) {
                workspace.formattedSize = I18n.toHumanSize(workspace.sizeInBytes, {precision: 0, format: "%n %u"});
            } else {
                workspace.percentageUsed = 0;
                workspace.formattedSize = t('data_sources.usage.offline');
            }
        });

        if(online) {
            return {
                formattedSandboxesSize: I18n.toHumanSize(context.sandboxesSizeInBytes, {precision: 0, format: "%n %u"})
            };
        }
        else {
            return {formattedSandboxesSize: t('data_sources.usage.offline')};
        }
    }
});