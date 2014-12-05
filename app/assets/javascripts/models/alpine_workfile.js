//= require ./workfile
chorus.models.AlpineWorkfile = chorus.models.Workfile.include(
    chorus.Mixins.DataSourceCredentials.model
).extend({
    constructorName: "AlpineWorkfile",
    parameterWrapper: "workfile",

    defaults: {
        entitySubtype: "alpine"
    },

    urlTemplate: function(options) {
        var action = options && options.workflow_action;
        if (action === 'run') {
            return 'workfiles/{{id}}/run';
        } else if (action === 'stop') {
            return 'workfiles/{{id}}/stop';
        } else {
            return this._super('urlTemplate', arguments);
        }
    },

    dataSourceRequiringCredentials: function() {
        if (typeof(this.serverErrors.modelData.entityType) !== 'undefined' && this.serverErrors.modelData.entityType !== "workspace") {
            return this._super('dataSourceRequiringCredentials');
        }
    },

    showUrlTemplate: function(options) {
        if (options && options.workFlow) {
            return "work_flows/{{id}}";
        }

        return this._super("showUrlTemplate", arguments);
    },

    iconUrl: function(options) {
        return chorus.urlHelpers.fileIconUrl('afm', options && options.size);
    },

    iframeUrl: function() {
        var uri = this.alpineUrlBase();
        var queryParams = {
            workfile_id: this.id,
            session_id: chorus.session.get("sessionId"),
            method: "chorusEntry"
        };

        uri.addQuery(queryParams);

        return uri.toString();
    },

    imageUrl: function() {
        var uri = this.alpineUrlBase();
        uri.addQuery({
            method: "chorusImage",
            workfile_id: this.id,
            session_id: chorus.session.get('sessionId')
        });
        return uri.toString();
    },

    alpineUrlBase: function() {
        return URI({ path: "/alpinedatalabs/main/chorus.do" });
    },

    isAlpine: function() {
        return true;
    },

    canOpen: function canOpen() {
        return this.workspace().currentUserCanCreateWorkFlows();
    },

    workFlowShowUrl: function() {
        return "#/work_flows/" + this.id;
    },

    executionLocations: function () {
        return _.map(this.get('executionLocations'), function (executionLocation) {
            return new chorus.models.DynamicExecutionLocation(executionLocation);
        }, this);
    },

    notifyWorkflowLimitedDataSource: function() {
        function isReadOnlyHdfs(el) {
            return el.get('entityType') === 'hdfs_data_source' && el.get('hdfsVersion') === 'Apache Hadoop 1.2';
        }

        _.every(this.executionLocations(), function(el) {
            if (isReadOnlyHdfs(el)) {
                chorus.toast("work_flows.toast.hdfs_read_only");
                return false;
            }
            return true;
        });
    },

    run: function () {
        this.save({}, {
            workflow_action: 'run',
            method: 'create',
            unprocessableEntity: function() { chorus.toast('work_flows.start_running_unprocessable', {toastOpts: {type: 'error'}}); }
        });
    },

    stop: function () {
        this.save({}, {workflow_action: 'stop', method: 'create'});
    }
});
