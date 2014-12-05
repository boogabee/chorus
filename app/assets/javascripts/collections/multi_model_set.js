chorus.Mixins.MultiModelSet = {
    //backbone enforces id uniqueness within a collection.
    //use padded IDs to ignore ID collisions within collections of multiple types
    //todo: Cloning this collection will mangle the model ids
    _prepareModel: function () {
        var model = this._super('_prepareModel', arguments);
        model.id = this.idTemplate(model);
        return model;
    },

    idTemplate: function(model) {
        return model.id + model.constructorName;
    }
};
