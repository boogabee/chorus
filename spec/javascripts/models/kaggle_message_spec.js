describe("chorus.models.KaggleMessage", function() {
    beforeEach(function () {
        this.kaggleUser = backboneFixtures.kaggleUserSet().at(0);
        this.kaggleUser.set({'id': 1});
        this.attrs = {
            recipients: new chorus.collections.KaggleUserSet(this.kaggleUser),
            subject: 'This is a valid subject',
            replyTo: 'user@emc.com',
            htmlBody: 'Please analyze my data'
        };
        this.model = new chorus.models.KaggleMessage(this.attrs);
    });

    describe("url", function() {
        it("equals /kaggle/messages", function() {
            expect(this.model.url()).toMatchUrl('/kaggle/messages');
        });
    });

    describe("params", function() {
        it("includes the correct parameters", function() {
            this.model.save();
            var json = this.server.lastCreate().json();
            expect(json["recipient_ids"]).toEqual([1]);
            expect(json["reply_to"]).toEqual("user@emc.com");
            expect(json["html_body"]).toEqual("Please analyze my data");
            expect(json["subject"]).toEqual("This is a valid subject");
        });
    });

    describe("validations", function() {
        it("can be valid", function() {
            expect(this.model.performValidation(this.attrs)).toBeTruthy();
        });

        it("requires from address", function () {
            this.attrs.replyTo = "";
            expect(this.model.performValidation(this.attrs)).toBeFalsy();
            expect(this.model.errors.replyTo).toBeTruthy();
        });

        it("requires from address to be a valid email", function() {
            this.attrs.replyTo = "notavalid/email.com";
            expect(this.model.performValidation(this.attrs)).toBeFalsy();
            expect(this.model.errors.replyTo).toBeTruthy();
        });

        it("requires subject", function () {
            this.attrs.subject = "";
            expect(this.model.performValidation(this.attrs)).toBeFalsy();
            expect(this.model.errors.subject).toBeTruthy();
        });

        it("requires a message", function() {
            this.attrs.htmlBody = "";
            expect(this.model.performValidation(this.attrs)).toBeFalsy();
            expect(this.model.errors.htmlBody).toBeTruthy();
        });
    });
});