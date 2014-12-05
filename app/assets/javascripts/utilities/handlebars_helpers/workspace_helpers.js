chorus.handlebarsHelpers.workspace = {
    workspaceUsage: function(percentageUsed, sizeText) {
        var markup = "";
        if (percentageUsed >= 100) {
            markup = '<div class="usage_bar">' +
                '<div class="used full" style="width: 100%;">' +
                '<span class="size_text">' + sizeText + '</span>' +
                '<span class="percentage_text">' + percentageUsed + '%</span>' +
                '</div>' +
                '</div>';
        } else {
            if (percentageUsed >= 50) {
                markup = '<div class="usage_bar">' +
                    '<div class="used" style="width: ' + percentageUsed + '%;">' +
                    '<span class="size_text">' + sizeText + '</span></div>' +
                    '</div>';
            } else {
                markup = '<div class="usage_bar">' +
                    '<div class="used" style="width: ' + percentageUsed + '%;"></div>' +
                    '<span class="size_text">' + sizeText + '</span>' +
                    '</div>';
            }
        }
        return new Handlebars.SafeString(markup);
    },

    usedInWorkspaces: function(workspaceSet, contextObject) {
        contextObject = contextObject.clone();
        if (!workspaceSet || workspaceSet.length === 0) { return ""; }

        if (!(workspaceSet instanceof chorus.collections.WorkspaceSet)) {
            workspaceSet = new chorus.collections.WorkspaceSet(workspaceSet);

        }

        function linkToContextObject(workspace) {
            contextObject.setWorkspace(workspace);
            return Handlebars.helpers.linkTo(contextObject.showUrl(), workspace.get('name'), {
                title: workspace.get('name')
            }).toString();
        }

        var workspaceLink = linkToContextObject(workspaceSet.at(0));

        var result = $("<div></div>").addClass('found_in workspace_association');
        var otherWorkspacesMenu = Handlebars.helpers.linkTo('#', t('workspaces_used_in.other_workspaces', {count: workspaceSet.length - 1}), {'class': 'open_other_menu'}).toString();

        result.append(t('workspaces_used_in.body', {workspaceLink: workspaceLink, otherWorkspacesMenu: otherWorkspacesMenu, count: workspaceSet.length }));
        if (workspaceSet.length > 1) {
            var list = $('<ul></ul>').addClass('other_menu');
            _.each(_.rest(workspaceSet.models), function(workspace) {
                list.append($('<li></li>').html(linkToContextObject(workspace)));
            });
            result.append(list);
        }

        return new Handlebars.SafeString(result.outerHtml());
    }
};

_.each(chorus.handlebarsHelpers.workspace, function(helper, name) {
    Handlebars.registerHelper(name, helper);
});