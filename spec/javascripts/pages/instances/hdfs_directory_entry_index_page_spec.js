describe("chorus.pages.HdfsDirectoryEntryIndexPage", function() {
    beforeEach(function() {
        this.instance = fixtures.instance({id: "1234", name: "instance Name"});
        this.page = new chorus.pages.HdfsDirectoryEntryIndexPage("1234", "foo");
    });

    it("fetches the Hdfs entries for that directory", function() {
        expect(this.page.collection).toHaveBeenFetched();
    });

    it("fetches the instance", function() {
        expect(this.page.instance).toHaveBeenFetched();
    });

    describe("when all of the fetches complete", function() {
        beforeEach(function() {
            var entries = fixtures.hdfsDirectoryEntrySet(null, {instanceId: "1234", path: "/foo"});
            entries.loaded = true;
            this.server.completeFetchFor(this.page.collection, entries);
            this.page.collection = entries;
            this.server.completeFetchFor(this.page.instance, this.instance);
        });

        it("should have title in the mainContentList", function() {
            expect(this.page.mainContent.contentHeader.options.title).toBe(this.instance.get("name") + ": /foo");
        });

        it("should have the right breadcrumbs", function() {
            expect(this.page.$(".breadcrumb:eq(0) a").attr("href")).toBe("#/");
            expect(this.page.$(".breadcrumb:eq(0)").text().trim()).toMatchTranslation("breadcrumbs.home");

            expect(this.page.$(".breadcrumb:eq(1) a").attr("href")).toBe("#/instances");
            expect(this.page.$(".breadcrumb:eq(1)").text().trim()).toMatchTranslation("breadcrumbs.instances");

            expect(this.page.$(".breadcrumb:eq(2)").text().trim()).toBe(this.instance.get("name") + " (1)");

            expect(this.page.$(".breadcrumb").length).toBe(3);
        });

        it("should have a sidebar", function() {
            expect($(this.page.el).find(this.page.sidebar.el)).toExist();
            expect(this.page.sidebar).toBeA(chorus.views.HdfsDirectoryEntrySidebar);
        })

        it("shows a link if a file is not binary", function() {
            var filename = this.page.collection.models[1].get('name')
            expect(this.page.$(".hdfs_directory_entry_list li:eq(1) .name a").attr('href')).toEqual('#/instances/1234/browse/foo/' + filename)
        })

        it("shows no link if a file is binary", function() {
            expect(this.page.$(".hdfs_directory_entry_list li:eq(2) .name a")).not.toExist()
        })

        it("shows no link if isBinary equals 'null'", function() {
            expect(this.page.$(".hdfs_directory_entry_list li:eq(3) .name a")).not.toExist()
        })

        describe("when the path is long", function() {
            beforeEach(function() {
                spyOn(chorus, "menu")

                this.page = new chorus.pages.HdfsDirectoryEntryIndexPage("1234", "start/m1/m2/m3/end");
                var entries = fixtures.hdfsDirectoryEntrySet(null, {instanceId: "1234", path: "/foo"});
                entries.loaded = true;
                this.server.completeFetchFor(this.page.collection, entries);
                this.page.collection = entries;
                this.server.completeFetchFor(this.page.instance, this.instance);
            });

            it("ellipsizes the inner directories", function() {
                expect(this.page.mainContent.contentHeader.options.title).toBe(this.instance.get("name") + ": /start/.../end");
            })

            it("constructs the breadcrumb links correctly", function() {
                var options = chorus.menu.mostRecentCall.args[1]

                var $content = $(options.content);

                expect($content.find("a").length).toBe(5);

                expect($content.find("a").eq(0).attr("href")).toBe("#/instances/1234/browse/")
                expect($content.find("a").eq(1).attr("href")).toBe("#/instances/1234/browse/start")
                expect($content.find("a").eq(2).attr("href")).toBe("#/instances/1234/browse/start/m1")
                expect($content.find("a").eq(3).attr("href")).toBe("#/instances/1234/browse/start/m1/m2")
                expect($content.find("a").eq(4).attr("href")).toBe("#/instances/1234/browse/start/m1/m2/m3")

                expect($content.find("a").eq(0).text()).toBe(this.instance.get("name"))
                expect($content.find("a").eq(1).text()).toBe("start")
                expect($content.find("a").eq(2).text()).toBe("m1")
                expect($content.find("a").eq(3).text()).toBe("m2")
                expect($content.find("a").eq(4).text()).toBe("m3")
            })
        })
    })
})