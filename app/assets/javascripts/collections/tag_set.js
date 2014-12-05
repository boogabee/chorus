chorus.collections.TagSet = chorus.collections.Base.extend({
    urlTemplate: 'tags',
    model: chorus.models.Tag,
    constructorName: "TagSet"
});