chorus.models.Config = chorus.models.Base.extend({
    constructorName: "Config",
    urlTemplate:"config/",

    isExternalAuth: function() {
        return this.get("externalAuthEnabled");
    },

    fileSizeMbWorkfiles: function() {
        return this.get("fileSizesMbWorkfiles");
    },

    fileSizeMbCsvImports: function() {
        return this.get("fileSizesMbCsvImports");
    },

    restrictDataSourceCreation: function() {
        return this.get("restrictDataSourceCreation");
    },

    license: function() {
        if (!this._license) {
            this._license = new chorus.models.License(this.get("license"));
        }

        return this._license;
    },

    clear: function() {
        this._super("clear", arguments);
        delete this._license;
    }
}, {
    instance: function () {
        if (!this._instance) {
            this._instance = new chorus.models.Config();
        }

        return this._instance;
    }
});
