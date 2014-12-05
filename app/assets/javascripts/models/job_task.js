chorus.models.JobTask = chorus.models.Base.extend({
    constructorName: 'JobTask',
    urlTemplate: "workspaces/{{workspace.id}}/jobs/{{job.id}}/job_tasks/{{id}}",
    showUrlTemplate: "workspaces/{{workspace.id}}/jobs/{{job.id}}/tasks/{{id}}",
    paramsToIgnore: ['workspace', 'job'],

    job: function () {
        if (!this._job && this.get("job")) {
            this._job = new chorus.models.Job(this.get("job"));
        }
        return this._job;
    },

    initialize: function () {
        this.set('workspace', this.job().workspace());
    },

    declareValidations: function(newAttrs) {
        if (newAttrs.action === "import_source_data") {
            if (!newAttrs.destinationId) {
                this.requirePattern("destinationName", chorus.ValidationRegexes.ChorusIdentifier64(), newAttrs, 'import.validation.toTable.required');
            }

            if (newAttrs.rowLimit) {
                this.requirePositiveInteger("rowLimit", newAttrs, 'import.validation.sampleCount.positive');
            }
        }
    }
});