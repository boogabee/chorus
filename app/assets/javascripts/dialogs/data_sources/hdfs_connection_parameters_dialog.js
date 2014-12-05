chorus.dialogs.HdfsConnectionParameters = chorus.dialogs.Base.extend({
    constructorName: 'HdfsConnectionParametersDialog',
    templateName: 'hdfs_connection_parameters',
    title: t('hdfs_connection_parameters.dialog.title'),
    additionalClass: "dialog_wide",

    events: {
        'click a.add_pair': 'addPair',
        'click a.remove_pair': 'removePair',
        'click button.submit': 'save'
    },

    setup: function () {
        this.pairs = this.model.get('connectionParameters') || [{key: '', value: ''}];
    },

    save: function (e) {
        e && e.preventDefault();

        this.preservePairs();
        this.model.set('connectionParameters', this.pairs);
        this.closeModal();
    },

    addPair: function (e) {
        e && e.preventDefault();

        this.preservePairs();
        this.pairs.push({key: '', value: ''});
        this.render();
    },

    removePair: function (e) {
        e && e.preventDefault();
        var pair = $(e.target).closest('.pair');
        pair.remove();
    },

    preservePairs: function () {
        this.pairs = _.map(this.$('.pair'), function (input) {
            return {
                key: $(input).find('.key').val(),
                value: $(input).find('.value').val()
            };
        });
    },

    additionalContext: function () {
        return {
            connectionParameters: this.pairs
        };
    }

});