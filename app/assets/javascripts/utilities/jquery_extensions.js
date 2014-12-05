jQuery.fn.extend({
    startLoading: function(translationKey, opts) {
        opts = opts || {};
        this.each(function() {
            var el = $(this);
            if (el.isLoading()) return;

            var spinner = new Spinner(_.extend({
                lines: 12,
                length: 3,
                width: 2,
                radius: 3,
                color: '#000',
                speed: 1,
                trail: 75,
                shadow: false
            }, opts)).spin();

            var originalHtml = el.html();
            var text = translationKey ? t(translationKey) : '';
            el.text(text).
                append(spinner.el).
                data("loading-original-html", originalHtml).
                addClass("is_loading");

            if (el.is("button")) {
                el.prop("disabled", true);
            }
        });
    },

    isOnDom: function() {
        return jQuery.contains(document.body, this[0]);
    },

    stopLoading: function() {
        this.each(function() {
            var el = $(this);
            if (!el.isLoading()) return;
            var originalHtml = el.data("loading-original-html");
            // $.text(val) clears the selected element, so .text here kills the spinner inside the button.
            el.removeData("loading-original-html").removeClass("is_loading").prop("disabled", false).html(originalHtml);
        });
    },

    isLoading: function() {
        return this.eq(0).hasClass("is_loading");
    },

    outerHtml: function() {
        var div = $("<div></div>");
        return div.append(this.clone()).html();
    }
});

jQuery.stripHtml = function(string) {
    return $("<div>" + string + "</div>").text();
};
