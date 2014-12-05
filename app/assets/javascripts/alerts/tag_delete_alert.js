chorus.alerts.TagDelete = chorus.alerts.ModelDelete.extend({
    constructorName: "TagDelete",

    text:t("tag.delete.text"),
    ok:t("tag.delete.button"),
    deleteMessage:"tag.delete.toast",

    setup:function () {
        this.title = t("tag.delete.title", this.deleteMessageParams());
    },

    deleteMessageParams:function () {
        return {tagName:this.model.get("name")};
    }
});
