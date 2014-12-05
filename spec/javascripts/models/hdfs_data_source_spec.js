describe("chorus.models.HdfsDataSource", function() {
    beforeEach(function() {
        this.model = backboneFixtures.hdfsDataSource({id : 123, username: "hadoop", groupList: "hadoop"});
        this.attrs = {};
    });

    it("has the right url", function() {
        expect(this.model.url()).toBe("/hdfs_data_sources/123");
    });

    it("is shared", function() {
        expect(this.model.isShared()).toBeTruthy();
    });

    it("has the correct entityType", function() {
        expect(this.model.entityType).toBe("hdfs_data_source");
    });

    it('links to the root directory of the hadoop data source', function() {
        expect(this.model.showUrl()).toBe("#/hdfs_data_sources/" + this.model.get('id') + "/browse/");
    });

    it("returns true for isHadoop", function() {
        expect(this.model.isHadoop()).toBeTruthy();
    });

    _.each(["name", "host", "username", "groupList"], function(attr) {
        it("requires " + attr, function() {
            this.attrs[attr] = "";
            expect(this.model.performValidation(this.attrs)).toBeFalsy();
            expect(this.model.errors[attr]).toBeTruthy();
        });
    });

    it("requires name with valid length", function() {
        this.attrs.name = "testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest";
        expect(this.model.performValidation(this.attrs)).toBeFalsy();
        expect(this.model.errors.name).toMatchTranslation("validation.required_pattern", {fieldName: "name"});
    });

    it("requires a job tracker port, if a job tracker host is present", function() {
        this.model.performValidation(this.attrs);
        expect(this.model.errors.jobTrackerHost).toBeFalsy();
        expect(this.model.errors.jobTrackerPort).toBeFalsy();

        this.attrs.jobTrackerHost = "test-job-tracker.com";
        expect(this.model.performValidation(this.attrs)).toBeFalsy();
        expect(this.model.errors.jobTrackerPort).toBeTruthy();
        this.attrs.jobTrackerPort = "foobar";
        expect(this.model.performValidation(this.attrs)).toBeFalsy();
        expect(this.model.errors.jobTrackerPort).toMatchTranslation("validation.required_pattern", {fieldName: "jobTrackerPort"});
        this.attrs.jobTrackerPort = "4321";
        expect(this.model.performValidation(this.attrs)).toBeTruthy();
    });

    it("requires a Name Node port only when High Availability is false", function () {
        this.attrs.host = 'a_host';
        this.attrs.highAvailability = 'false';
        this.attrs.port = '';
        this.model.performValidation(this.attrs);
        expect(this.model.errors.port).toBeTruthy();

        this.attrs.highAvailability = 'true';
        this.model.performValidation(this.attrs);
        expect(this.model.errors.port).toBeFalsy();
    });

    describe("#sharedAccountDetails", function() {
        it('returns the account name of the user who owns the data source and shared it', function() {
            var sharedAccountDetails = this.model.get("username") + ", " + this.model.get("groupList");
            expect(this.model.sharedAccountDetails()).toBe(sharedAccountDetails);
        });
    });

    describe("#version", function() {
        it("returns the hdfsVersion attribute (not the adaptor version)", function () {
            this.model.set("hdfsVersion", "spacejam");
            expect(this.model.version()).toBe("spacejam");
        });
    });
});
