describe("chorus.views.SearchHdfsEntry", function() {
    beforeEach(function() {
        this.result = backboneFixtures.searchResult();
        this.model = this.result.hdfs_entries().first();
        this.model.set('highlightedAttributes', {});
    });

    var ancestorId = 42;
    var setModelPath = function (model, path) {
        var parts = path.split('/');
        var name = _.last(parts);
        var ancestors = _.map(parts, function (part) {
            return {
                name: part || "root",
                id: ancestorId++
            };
        });
        ancestors.pop();
        ancestors = ancestors.reverse();

        model.set({
            name: name,
            path: path,
            ancestors: ancestors
        });
    };

    describe("getHighlightedPathSegments", function() {
        context("when there are no highlights", function() {
            beforeEach(function() {
                setModelPath(this.model, '/aaa/bbb');
                this.view = new chorus.views.SearchHdfsEntry({model: this.model});
                this.view.render();
            });

            it("should return the path segments without highlighting", function() {
                expect(this.view.getHighlightedPathSegments()).toEqual(["aaa", "bbb"]);
            });
        });

        context("when there are highlights", function() {
            beforeEach(function() {
                this.model.set('highlightedAttributes', {path: ['/<em>aaa</em>/bbb/ccc']});
                setModelPath(this.model, '/aaa/bbb/ccc');
                this.view = new chorus.views.SearchHdfsEntry({model: this.model});
                this.view.render();
            });

            it("should return an array of path segments with highlighting", function() {
                expect(this.view.getHighlightedPathSegments()).toEqual(["<em>aaa</em>", "bbb", "ccc"]);
            });
        });
    });

    describe("when the file is not a binary file", function() {
        beforeEach(function() {
            this.model.set({isBinary: false, highlightedAttributes: {path: ['/<em>aaa</em>/bbb']} });
            setModelPath(this.model, '/aaa/bbb');
            this.view = new chorus.views.SearchHdfsEntry({model: this.model});
            this.view.render();
        });

        it("should render the name for each file", function() {
            expect(this.view.$("a.name")).toContainText(this.model.get("name"));
        });

        it('should render the data source location', function() {
            var $inst = this.view.$(".data_source a");

            expect($inst.text()).toBe(this.model.getHdfsDataSource().name());
            expect($inst.attr("href")).toBe(this.model.getHdfsDataSource().showUrl());
        });

        it("should render a link to each file", function() {
            expect(this.view.$('a.name').attr('href')).toMatchUrl(this.model.showUrl());
        });

        it("should render the location for each file", function() {
            var $links = this.view.$(".path_parts a");
            expect($links.length).toBe(2);

            expect($links.eq(0).html()).toEqual("<em>aaa</em>");
            expect($links.eq(0).attr("href")).toBe("#/hdfs_data_sources/" + this.model.getHdfsDataSource().id + "/browse/" + this.model.get('ancestors')[0].id);

            expect($links.eq(1).html()).toEqual("bbb");
            expect($links.eq(1).attr("href")).toBe(this.model.showUrl());
        });
    });

    describe("when the file is a binary file", function() {
        beforeEach(function() {
            this.model.set({isBinary: true});
            setModelPath(this.model, '/aaa/bbb');
            this.view = new chorus.views.SearchHdfsEntry({model: this.model});
            this.view.render();
        });

        it('should render the data source location', function() {
            var $inst = this.view.$(".data_source a");

            expect($inst.text()).toBe(this.model.getHdfsDataSource().name());
            expect($inst.attr("href")).toBe(this.model.getHdfsDataSource().showUrl());
        });

        it("should not render a link to each file", function() {
            expect(this.view.$('a.name')).not.toExist();
            expect(this.view.$("span.name").text()).toContainText(this.model.get("name"));
        });

        it("should render the location for each file", function() {
            var $links = this.view.$(".path_parts a");
            expect($links.length).toBe(2);

            expect($links.eq(0).text()).toBe("aaa");
            expect($links.eq(0).attr("href")).toBe("#/hdfs_data_sources/" + this.model.getHdfsDataSource().id + "/browse/" + this.model.get('ancestors')[0].id);

            expect($links.eq(1).text()).toBe("bbb");
            expect($links.eq(1).attr("href")).toMatchUrl(this.model.showUrl());
        });
    });

    describe("tags", function() {
        beforeEach(function() {
            this.view = new chorus.views.SearchHdfsEntry({model: this.model});
        });

        itBehavesLike.ItPresentsModelWithTags();
    });
});
