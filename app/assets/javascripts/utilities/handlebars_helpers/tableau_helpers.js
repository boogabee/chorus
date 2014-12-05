chorus.handlebarsHelpers.tableau = {
    usedInTableau: function(tableauWorkbookSet) {
        if (!tableauWorkbookSet || tableauWorkbookSet.length === 0) { return ""; }

        if (!(tableauWorkbookSet instanceof chorus.collections.TableauWorkbookSet)) {
            tableauWorkbookSet = new chorus.collections.TableauWorkbookSet(tableauWorkbookSet);

        }

        function linkToContextObject(workbook) {
            return Handlebars.helpers.linkTo(workbook.get("url"), workbook.get('name'), {
                title: workbook.get('name'),
                target: "_blank"
            }).toString();
        }

        var workbookLink = linkToContextObject(tableauWorkbookSet.at(0));

        var result = $("<div></div>").addClass('published_to');
        var otherWorkbooksMenu = Handlebars.helpers.linkTo('#', t('tableau.other_workbooks', {count: tableauWorkbookSet.length - 1}), {'class': 'open_other_menu'}).toString();

        result.append(t('tableau.body',
            {
                tableauIcon: Handlebars.helpers.tableauIcon(),
                workbookLink: workbookLink,
                otherWorkbooksMenu: otherWorkbooksMenu,
                count: tableauWorkbookSet.length
            }
        ));
        if (tableauWorkbookSet.length > 1) {
            var list = $('<ul></ul>').addClass('other_menu');
            _.each(_.rest(tableauWorkbookSet.models), function(workbook) {
                list.append($('<li></li>').html(linkToContextObject(workbook)));
            });
            result.append(list);
        }

        return new Handlebars.SafeString(result.outerHtml());
    },

    fromTableau: function(workfile) {
        return new Handlebars.SafeString(t('workfiles.tableau.from', {
                tableauIcon: Handlebars.helpers.tableauIcon(),
                tableauLink: Handlebars.helpers.linkTo(workfile.get('workbookUrl'), workfile.get('workbookUrl'), { "class":'tableau', target: '_blank' })
            }
        ));
    },

    tableauIcon: function () {
        return new Handlebars.SafeString(($('<span/>').addClass('tableau_icon')).outerHtml());
    }
};

_.each(chorus.handlebarsHelpers.tableau, function(helper, name) {
    Handlebars.registerHelper(name, helper);
});
