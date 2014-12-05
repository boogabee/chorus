(function() {

    var templates = {}; //for memoizing handlebars helpers templates
    chorus.handlebarsHelpers.link = {
        moreLink: function(collection, max, more_key, less_key) {
            if (collection && collection.length > max) {
                templates.moreLinks = templates.moreLinks || Handlebars.compile(
                    ["<ul class='morelinks'>",
                        "<li><a class='more' href='#'>{{t more_key count=more_count}}</a></li>",
                        "<li><a class='less' href='#'>{{t less_key count=more_count}}</a></li>",
                        "</ul>"].join('')
                );

                return templates.moreLinks({
                    more_key: more_key,
                    more_count: collection.length - max,
                    less_key: less_key
                });
            } else {
                return "";
            }
        },

        eachWithMoreLink: function(context, max, more_key, less_key, showLast, block) {
            var ret = "";

            if (context && context.length > 0) {
                for (var i = 0, j = context.length; i < j; i++) {
                    if(showLast) {
                        context[i].moreClass = (j >= max && i < (j - max)) ? "more" : "";
                    } else {
                        context[i].moreClass = (i >= max) ? "more" : "";
                    }

                    ret = ret + block.fn(context[i]);
                }
                ret += Handlebars.helpers.moreLink(context, max, more_key, less_key);
            } else {
                ret = block.inverse(this);
            }
            return ret;
        },


        fileIconUrl: function(key, size) {
            return chorus.urlHelpers.fileIconUrl(key, size);
        },

        linkTo: function(url, text, attributes) {
            var link = $("<a></a>").attr("href", url).attr(attributes || {});

            link.html(Handlebars.Utils.escapeExpression(text));

            return new Handlebars.SafeString(link.outerHtml());
        }
    };

    _.each(chorus.handlebarsHelpers.link, function(helper, name) {
        Handlebars.registerHelper(name, helper);
    });
})();