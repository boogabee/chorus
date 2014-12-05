chorus.dialogs.Upload = chorus.dialogs.Base.extend({
    constructorName: "UploadDialog",
    templateName: "upload_dialog",
    title: t("upload.dialog.title"),
    submitKey: "upload.dialog.submit",

    setup: function() {
        this.config = chorus.models.Config.instance();
    },

    makeModel: function() {
        this.resource = this.model = this.upload = new chorus.models.Upload();
    },

    events: {
        "submit form": "uploadFile",
        "click button.submit": "uploadFile"
    },

    uploadFile: function(e) {
        e && e.preventDefault();
        this.$("button.choose").prop("disabled", true);
        this.$(".file-wrapper a").addClass("hidden");

        this.$("button.submit").startLoading("actions.uploading");
        this.uploadObj.url = "/uploads";
        this.uploadObj.source = "fs";
        this.request = this.uploadObj.submit();
    },

    modalClosed: function() {
        if (this.request) {
            this.request.abort();
        }

        this._super("modalClosed");
    },

    fileChosen: function(e, data) {
        this.$("button.submit").prop("disabled", false);
        this.$('.empty_selection').addClass('hidden');

        this.uploadObj = data;
        var filename = data.files[0].name;
        var filenameComponents = filename.split('.');
        var basename = _.first(filenameComponents);
        var extension = _.last(filenameComponents);
        this.$(".file_name").text(filename);
        this.$(".new_table input[type='text']").val(basename.toLowerCase().replace(/ /g, '_'));

        this.$("img").removeClass("hidden");
        this.$("img").attr("src", chorus.urlHelpers.fileIconUrl(extension, "icon"));

        this.$(".file-wrapper a").removeClass("hidden");
        this.$(".file-wrapper button").addClass("hidden");

        this.$("input[type=file]").prop("title", t("dataset.import.change_file"));

        this.validateFileSize();
    },

    validateFileSize: function() {
        this.clearErrors();
        if (!this.model) return;

        var maxFileSize = this.maxFileSize();

        if (maxFileSize) {
            _.each( this.uploadObj.files, function(file) {
                if (file.size > (maxFileSize * 1024 * 1024)) {
                    this.model.serverErrors = {
                        "fields": {
                            "base": {
                                "FILE_SIZE_EXCEEDED": {
                                    "count": maxFileSize
                                }
                            }
                        }
                    };
                    this.$("button.submit").prop("disabled", true);
                    this.showErrors(this.model);
                }
            }, this);
        }
    },

    maxFileSize: $.noop,

    uploadFinished: function(e) {
        e && e.preventDefault();

        this.$(".file-wrapper a").removeClass("hidden");
        this.$("button.submit").stopLoading();
    },

    uploadFailed: function(e, response) {
        e && e.preventDefault();

        this.$(".file-wrapper a").removeClass("hidden");
        this.$(".import_controls input[type=radio]").prop("disabled", false);
        try {
            var errors = JSON.parse(response.jqXHR.responseText).errors;
            if(errors.fields.contents_file_size && errors.fields.contents_file_size.LESS_THAN) {
                var count = errors.fields.contents_file_size.LESS_THAN.count;
                errors.fields.contents_file_size.LESS_THAN.count = count.split(" ")[0]/1024/1024 + " MB";
            }
            this.model.serverErrors = errors;
        } catch(error) {
            var status = response.jqXHR.status;
            var statusText = response.jqXHR.statusText;
            this.displayNginxError(status, statusText);
        }
        this.model && this.model.trigger("saveFailed");
    },

    displayNginxError: function(status, statusText) {
        this.model.serverErrors = {
            "fields": {
                "base": {
                    GENERIC: {
                        message: status + ": " + statusText
                    }
                }
            }
        };
    },

    uploadSuccess: function(e, data) {
        e && e.preventDefault();

        this.closeModal();
    },

    postRender: function() {
        this.$("input[type=file]").fileupload({
            change: _.bind(this.fileChosen, this),
            add: _.bind(this.fileChosen, this),
            done: _.bind(this.uploadSuccess, this),
            fail: _.bind(this.uploadFailed, this),
            always: _.bind(this.uploadFinished, this),
            dataType: "json"
        });
    },

    additionalContext: function() {
        return { submitKey: this.submitKey };
    }

});
