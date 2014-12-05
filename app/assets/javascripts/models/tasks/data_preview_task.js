chorus.models.DataPreviewTask = chorus.models.Task.extend({
    nameAttribute: "objectName",

    urlTemplateBase: "datasets/{{dataset.id}}/previews"

});

