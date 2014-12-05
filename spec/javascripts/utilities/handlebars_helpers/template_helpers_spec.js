describe('chorus.handlebarsHelpers.template', function() {
    describe("renderTemplate", function () {
        it("renders the template", function () {
            expect(Handlebars.helpers.renderTemplate('plain_text', {text:'foo'}).toString().trim()).toBe('foo');
        });
    });

    describe("renderTemplateIf", function () {
        beforeEach(function () {
            this.template = '{{renderTemplateIf condition "plain_text" this }}';
        });

        it("renders the template if the condition is truthy", function () {
            var output = Handlebars.compile(this.template)({ condition:true, text:"hello" });
            expect(output).toContainText("hello");
        });

        it("does not render the template if the condition is falsy", function () {
            var output = Handlebars.compile(this.template)({ condition:false, text:"hello" });
            expect(output).toBe("");
        });
    });

    describe("spanFor", function() {
        it("wraps text in span and applies attributes", function() {
            var span = Handlebars.helpers.spanFor("text", {'class': 'my_class'}).toString();
            expect(span).toEqual('<span class="my_class">text</span>');
        });

        it("escapes the text", function() {
            var span = Handlebars.helpers.spanFor("<span>text</span>").toString();
            expect(span).toEqual('<span>&lt;span&gt;text&lt;/span&gt;</span>');
        });

        it("should return a safe string", function() {
            expect(Handlebars.helpers.spanFor("text")).toBeA(Handlebars.SafeString);
        });
    });

    describe("hdfsDataSourceFields", function() {
        beforeEach(function() {
            spyOn(Handlebars.helpers, "renderTemplate");
        });

        it("renders the template for hdfs data source with the passed context", function() {
            Handlebars.helpers.hdfsDataSourceFields({param_one: "param"});
            expect(Handlebars.helpers.renderTemplate).toHaveBeenCalledWith("data_sources/hdfs_data_source_fields", {param_one: "param"});
        });

        it("renders the template for hdfs data source with an empty context when none is specified", function() {
            Handlebars.helpers.hdfsDataSourceFields();
            expect(Handlebars.helpers.renderTemplate).toHaveBeenCalledWith("data_sources/hdfs_data_source_fields", {});
        });
    });

    describe("hdfsVersionsSelect", function() {
        beforeEach(function() {
            this.versions = chorus.models.Config.instance().get("hdfsVersions");
            spyOn(Handlebars.helpers, "renderTemplate");
        });

        it("renders the template for hdfs data source with the passed context", function() {
            Handlebars.helpers.hdfsVersionsSelect(false);
            expect(Handlebars.helpers.renderTemplate).toHaveBeenCalledWith("data_sources/hdfs_versions_select", {
                selectOne: false,
                hdfsVersions: this.versions
            });
        });

        it("renders the template for hdfs data source with an empty context when none is specified", function() {
            Handlebars.helpers.hdfsVersionsSelect();
            expect(Handlebars.helpers.renderTemplate).toHaveBeenCalledWith("data_sources/hdfs_versions_select", {
                selectOne: true,
                hdfsVersions: this.versions
            });
        });
    });

    describe("dbDataSourceFields", function() {
        beforeEach(function() {
            spyOn(Handlebars.helpers, "renderTemplate");
        });

        it("renders the template for hdfs data source with the passed context", function() {
            Handlebars.helpers.dbDataSourceFields({param_one: "param"});
            expect(Handlebars.helpers.renderTemplate).toHaveBeenCalledWith("data_sources/db_data_source_fields", {param_one: "param"});
        });

        it("renders the template for hdfs data source with an empty context when none is specified", function() {
            Handlebars.helpers.dbDataSourceFields();
            expect(Handlebars.helpers.renderTemplate).toHaveBeenCalledWith("data_sources/db_data_source_fields", {});
        });
    });

    describe("jdbcDataSourceFields", function() {
        beforeEach(function() {
            spyOn(Handlebars.helpers, "renderTemplate");
        });

        it("renders the template for jdbc data source with the passed context", function() {
            Handlebars.helpers.jdbcDataSourceFields({param_one: "param"});
            expect(Handlebars.helpers.renderTemplate).toHaveBeenCalledWith("data_sources/jdbc_data_source_fields", {param_one: "param"});
        });

        it("renders the template for hdfs data source with an empty context when none is specified", function() {
            Handlebars.helpers.jdbcDataSourceFields();
            expect(Handlebars.helpers.renderTemplate).toHaveBeenCalledWith("data_sources/jdbc_data_source_fields", {});
        });
    });

    describe("modelNamesList", function () {
        beforeEach(function () {
            this.collection = new chorus.collections.Base();
            this.wf = backboneFixtures.workfile.alpine();
            this.ds = backboneFixtures.oracleDataset();
            this.user = backboneFixtures.user();
            this.ws = backboneFixtures.workspace();
            this.models = [this.wf, this.ds, this.user];
            this.collection.reset(this.models);
        });

        it("with 1 model returns the name", function () {
            this.models = [this.wf];
            this.collection.reset(this.models);
            var hbsSafe = Handlebars.helpers.modelNamesList(this.collection).toString();
            expect(hbsSafe).toBe(this.wf.name());
        });


        it("with 2 models returns and-ed list", function () {
            this.models = [this.wf, this.ds];
            this.collection.reset(this.models);
            var hbsSafe = Handlebars.helpers.modelNamesList(this.collection).toString();
            expect(hbsSafe).toBe(this.collection.map(function(model) { return model.name(); }).join(" and "));
        });

        it("with 3 models returns a comma separated list of the models", function() {
            this.models = [this.wf, this.ds, this.user];
            this.collection.reset(this.models);
            var hbsSafe = Handlebars.helpers.modelNamesList(this.collection).toString();
            expect(hbsSafe).toBe(this.wf.name() + ", " + this.ds.name() + ", and " + this.user.name());
        });


        it("with 4 models returns the first 2 and count others", function() {
            this.models = [this.wf, this.ds, this.user, this.ws];
            this.collection.reset(this.models);
            var hbsSafe = Handlebars.helpers.modelNamesList(this.collection).toString();
            expect(hbsSafe).toBe(this.wf.name() + ", " + this.ds.name() + ", and 2 others");
        });

    });
});
