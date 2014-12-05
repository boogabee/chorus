chorus.PopupMenu = (function() {
    var currentMenu;
    var currentIndicator;

    var releaseClicks = function() {
        $(document).unbind("click.popup_menu");
    };

    var dismissPopups = function(parentView) {
        releaseClicks();
        parentView.$(".menu").addClass("hidden");
        currentIndicator && currentIndicator.removeClass("active");
    };

    var captureClicks = function(parentView) {
        $(document).bind("click.popup_menu", function(){ dismissPopups(parentView); });
    };

    return {
        toggle: function(parentView, selector, e, indicatorSelector) {
            if(e) {
                e.preventDefault();
                e.stopImmediatePropagation();
            }

            var previousMenu = currentMenu;
            currentMenu = parentView.$(selector);

            var isPoppedUp = !currentMenu.hasClass("hidden");
            dismissPopups(parentView);


            

            isPoppedUp || captureClicks(parentView);

            previousMenu && previousMenu.addClass("hidden");

            if (indicatorSelector) {
                currentIndicator = parentView.$(indicatorSelector);
                currentIndicator.toggleClass("active", !isPoppedUp);
            }
            
            currentMenu.toggleClass("hidden", isPoppedUp);
        },

        close: function(parentView) {
            dismissPopups(parentView);
        }
    };
})();