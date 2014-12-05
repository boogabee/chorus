(function() {
    var TextExtAjax = $.fn.textext.TextExtAjax;
    var TextExtAutocomplete = $.fn.textext.TextExtAutocomplete;

    TextExtAjax.prototype.onComplete = function(data, query)
    {
        var self   = this,
            result = data.response;

        self.dontShowLoading();

        var suggestions = _.reject(result, function(tag) {
            return self.opts('ajax.existingTagCollection').containsTag(tag.name);
        });

        _.each(suggestions, function(tag) {
            tag.text = Handlebars.Utils.escapeExpression(tag.name);
        });

        if(query.trim().length > 0 && !_.any(result, function(tag) { return tag.name === query; })) {
            var escapedQuery = Handlebars.Utils.escapeExpression(query);
            suggestions.unshift({text: escapedQuery + " <span class='create_new'>(" + t("tags.create_new") + ")</span>", name: query});
        }

        self.trigger('setSuggestions', { result : suggestions });
    };

    $.fn.textext.TextExt.prototype.invalidateBounds = function() {
        this.trigger('preInvalidate');
        this.trigger('postInvalidate');
    };

    var TextExtTags = $.fn.textext.TextExtTags;

    TextExtTags.prototype.onPreInvalidate = $.noop;

    TextExtTags.prototype.addTags = function(tags)
    {
        if(!tags || tags.length === 0)
            return;

        tags = _.flatten(_.inject(tags, function(results, tag) {
            if(tag.name.indexOf(',') >= 0) {
                results.push(_.map(tag.name.split(","), function(name) {
                    return { name: name };
                }));
            } else {
                results.push(tag);
            }
            return results;
        }, []));

        var self      = this,
            core      = self.core(),
            container = self.containerElement(),
            i, tag
            ;

        for(i = 0; i < tags.length; i++)
        {
            tag = tags[i];

            if(tag && self.isTagAllowed(tag))
                container.append(self.renderTag(tag));
        }

        container.append(self.input().detach());

        self.updateFormCache();
        core.getFormData();
        core.invalidateBounds();
    };

    TextExtAutocomplete.prototype.onShowDropdown = function(e, renderCallback)
    {
        var self        = this,
            suggestions = self._suggestions;

        if(!suggestions)
            return self.trigger('getSuggestions');

        if($.isFunction(renderCallback))
        {
            renderCallback(self);
        }
        else
        {
            self.renderSuggestions(self._suggestions);
        }

        self.showDropdown(self.containerElement());
    };

    TextExtAutocomplete.prototype.togglePreviousSuggestion = function()
    {
        var self     = this,
            selected = self.selectedSuggestionElement(),
            prev     = selected.prev()
            ;

        if(prev.length === 0) {
            self.hideDropdown();
            return;
        }

        self.clearSelected();
        prev.addClass("text-selected");
        self.scrollSuggestionIntoView(prev);
    };
})();
