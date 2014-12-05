chorus.Mixins.StickyHeader = {
    //This is largely untestable. Delete at your own risk.
    //Most of the pain is from making the header sticky if the page content requires scrolling, but
    //does not require scrolling when the header is position: fixed.

    //Fun Edge cases to consider:
        // - The page content requires scrolling with the results console, but not without it
        // - The page content requires scrolling if the codeMirror content has many lines.  Then you scroll down and then delete those lines

    bindStickyHeader: function() {
        if(!this.boundScrollHandler) {
            this.boundScrollHandler = _.bind(this.scrollHandler, this);
            $(window).scroll(this.boundScrollHandler);
        }
    },

    stickyHeaderElements: function() { return [this.$el]; },

    scrollHandler: function() {
        if (!this.$el) return;
        this.topPosition = this.topPosition || this.$el.offset().top;
        var distanceToTop = this.topPosition  - $(window).scrollTop();

        var $subNav = $(".sub_nav");
        var header =  $subNav.length ? $subNav : $(".header");
        var distanceToHeader = distanceToTop - header.outerHeight();
        this.contentDetailsAtTop = distanceToHeader <= 0;

        _.each(this.stickyHeaderElements(), _.bind(this.makeSpacerForElement, this));
    },

    makeSpacerForElement: function (elem, index) {
        var spacerClass = "scroll_spacer";
        var spacerClassToAvoidSpacerDups = spacerClass + index;

        elem = this.extractElementFromSelectionArrays(elem, spacerClass);

        if(this.contentDetailsAtTop) {
            //Before making the headers' positions fixed,
            //Make clones of the headers to prevent the DOM from collapsing
            if ($("."+spacerClassToAvoidSpacerDups).length === 0) {
                var $spacer = elem.clone();
                $spacer.addClass(spacerClass);
                $spacer.addClass(spacerClassToAvoidSpacerDups);
                $spacer.css("visibility", "hidden");
                elem.before($spacer);
            }
        } else {
            $("."+spacerClass).remove();
        }

        elem.toggleClass('fixed_header', this.contentDetailsAtTop);
    },

    teardownStickyHeaders: function() {
        $(window).unbind('scroll', this.boundScrollHandler);
        delete this.boundScrollHandler;
    },

    extractElementFromSelectionArrays: function (elem, spacerClass) {
        // Sometimes receives both the sticky element and its spacer clone.
        // Throw away the spacer clone.
        if (elem.length > 1) {
            elem = $(_.detect(elem, function (el) {
                return !($(el).hasClass(spacerClass));
            }));
        }
        return elem;
    }
};