chorus.views.ColorPaletteView = chorus.views.Base.extend({
    constructorName: "StyleGuideColorPaletteView",
    templateName: "style_guide_color_palette",

    backgroundColors: {
        "$body-background-color": "#EAEFF6",
        "$body-glow-color ": "#C8DCED",
        "$shaded-background-color": "#E1E5E9",
        "$data-grid-background-color": "#EAEEF2",
        "$dialog-background-color": "white",
        "$element-background": "white",
        "$button-background-color ": "white",
        "$list-hover-color": "#e3e8ed",
        "$list-checked-color": "#dde3e9",
        "$progress-bar-background-color ": "#D8DEE6",
        "$progress-bar-full-background-color ": "#AE0020",
        "$search-highlight-color": "#FFFF00",
        "$error-background-color": "#B61B1D",
        "$alert-background-color": "#B5121B",
        "$content-details-action-background-color": "#B3D988",
        "$content-details-create-background-color": "#49A942",
        "$content-details-chart-icon-hover-background-color": "#C3ECA0",
        "$content-details-chart-icon-selected-background-color": "#42AA3D",
        "$picklist-selected-background-color": "#3795DD",
        "$activity-stream-comment-background-color": "#DFE5EB",
        "$selected-row-hover-background-color": "#DCE2E8",
        "$chart-fill-color": "#4A83C3",
        "$dataset-number-background-color": "#788DA5",
        "$ie-header-color": "#c7c7c7",
        "$tab-gradient-color ": "#D5E0EB"
    },

    borderColors: {
        "$border-color": "#D0D0D0",
        "$weak-header-border-color": "#bebfc9",
        "$subheader-border-color": "#D1D4D7",
        "$subheader-border-color-dark": "#A4A6A8",
        "$guts-border-color": "#CCD2D7",
        "$pagination-border-color": "#A4A6A8",
        "$menu-border-color": "#B0B0B0",
        "$header-border-color": "#8A97A2",
        "$list-border-color": "#B9BBBD",
        "$content-details-action-link-border-color": "#98B675",
        "$results-console-border-color": "#88A8D3",
        "$type-ahead-result-border-color": "#A5A6A8"
    },

    textColors: {
        "$color-text1": "black",
        "$color-text2": "#5f5f5f",
        "$color-text3": "#7D7D7D",
        "$color-text4": "#959595",
        "$error-text-color": "white",
        "$error-color": "white",
        "$link-color": "#2c95dd",
        "$content-header-link-color": "$color-text4",
        "$content-details-action-link-color": "#4E7225",
        "$content-details-create-bar-link-color": "#608437",
        "$needs-attention-color": "#E44E12"
    },

    context: function () {
        return {
            backgroundColors: this.backgroundColors,
            borderColors: this.borderColors,
            textColors: this.textColors
        };
    }
});