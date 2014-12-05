chorus.models.WorkfileExecutionTask = chorus.models.Task.extend({
    urlTemplateBase: "workfiles/{{workfile.id}}/executions",
    constructorName: "",
    paramsToSave: ['checkId', 'sql'],

    name: function() {
        return this.get("workfile").get("fileName");
    }
});
