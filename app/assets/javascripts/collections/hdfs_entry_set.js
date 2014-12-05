chorus.collections.HdfsEntrySet = chorus.collections.Base.include(
    chorus.Mixins.DataSourceCredentials.model
).extend({
        constructorName: "HdfsEntrySet",
        model: chorus.models.HdfsEntry,

        urlTemplate: function() {
            return "hdfs_data_sources/{{hdfsDataSource.id}}/files/?id={{id}}";
        },

        modelAdded: function(model) {
            if(this.attributes.hdfsDataSource) model.set({ hdfsDataSource: this.attributes.hdfsDataSource}, { silent: true });
        },

        hdfsEntry: function() {
            var hdfsDataSource = this.attributes.hdfsDataSource;
            this._entry = this._entry || new chorus.models.HdfsEntry({ id: this.attributes.id, isDir: true, hdfsDataSource: hdfsDataSource });
            return this._entry;
        }
    });
