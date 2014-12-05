describe('chorus.handlebarsHelpers.workspace', function() {
    describe("workspaceUsage", function () {
        it("should never have a width greater than 100%", function () {
            expect($(Handlebars.helpers.workspaceUsage(101).toString()).find('.used').attr('style')).toContain("100%");
        });

        it("should be red if percentage is >= 100%", function () {
            expect($(Handlebars.helpers.workspaceUsage(99, '1GB').toString()).find('.used')).not.toHaveClass('full');
            expect($(Handlebars.helpers.workspaceUsage(100, '1GB').toString()).find('.used')).toHaveClass('full');
            expect($(Handlebars.helpers.workspaceUsage(101, '1GB').toString()).find('.used')).toHaveClass('full');
        });

        it("with percentage >= 100% it has percentage text", function () {
            expect($(Handlebars.helpers.workspaceUsage(99, '1GB').toString()).find('.percentage_text')).not.toExist();
            expect($(Handlebars.helpers.workspaceUsage(100, '1GB').toString()).find('.percentage_text')).toContainText('100%');
            expect($(Handlebars.helpers.workspaceUsage(101, '1GB').toString()).find('.percentage_text')).toContainText('101%');
        });

        it("with percentage >= 50 it has size text inside the used bar", function () {
            expect($(Handlebars.helpers.workspaceUsage(50, '1GB').toString()).find('.used .size_text')).toContainText('1GB');
            expect($(Handlebars.helpers.workspaceUsage(100, '1GB').toString()).find('.used .size_text')).toContainText('1GB');
            expect($(Handlebars.helpers.workspaceUsage(50, '1GB').toString()).find('> .size_text')).not.toExist();
        });

        it("with percentage < 50 it has size text outside the used bar", function () {
            expect($(Handlebars.helpers.workspaceUsage(49, '1GB').toString()).find('.used .size_text')).not.toExist();
            expect($(Handlebars.helpers.workspaceUsage(49, '1GB').toString()).find('> .size_text')).toContainText('1GB');
        });
    });

    describe("usedInWorkspaces", function () {
        function itIncludesTheFoundInWorkspaceInformation() {
            it("includes the 'found in workspace' information", function () {
                var workspace = this.workspaceList.at(0);
                expect($(this.result).find("a").attr("href")).toMatchUrl('#/' + workspace.get('id') + '/contextObject');
                expect($(this.result).find("a")).toContainText(workspace.get('name'));
                expect($(this.result).find("a")).toHaveAttr("title", workspace.get('name'));
            });
        }

        var contextObjectClass = chorus.models.Base.extend({
            showUrlTemplate:"{{workspaceId}}/contextObject",
            setWorkspace:function (workspace) {
                this.attributes.workspaceId = workspace.get('id');
            }
        });
        beforeEach(function () {
            this.contextObject = new contextObjectClass();
        });

        context("when the first arguments is an array", function () {
            beforeEach(function () {
                this.workspaceList = [backboneFixtures.workspace().attributes, backboneFixtures.workspace().attributes];
                this.result = Handlebars.helpers.usedInWorkspaces(this.workspaceList, this.contextObject).toString();
            });

            it("includes the 'found in workspace' information", function () {
                var workspace = this.workspaceList[0];
                expect($(this.result).find("a").attr("href")).toMatchUrl('#/' + workspace.id + '/contextObject');
                expect($(this.result).find("a")).toContainText(workspace.name);
                expect($(this.result).find("a")).toHaveAttr("title", workspace.name);
            });

            it("should indicate there is 1 other workspace", function () {
                expect($(this.result)).toContainTranslation("workspaces_used_in.other_workspaces", {count:1});
            });

        });

        context("when there is no data", function () {
            beforeEach(function () {
                this.result = Handlebars.helpers.usedInWorkspaces(undefined, this.contextObject);
            });

            it("does not render", function () {
                expect(this.result).toBeFalsy();
            });
        });

        context("when there aren't any 'found in' workspaces", function () {
            beforeEach(function () {
                this.workspaceList = new chorus.collections.WorkspaceSet([]);
                this.result = Handlebars.helpers.usedInWorkspaces(this.workspaceList, this.contextObject);
            });

            it("does not render", function () {
                expect(this.result).toBeFalsy();
            });
        });

        context("when there is exactly 1 'found in' workspace", function () {
            beforeEach(function () {
                this.workspaceList = new chorus.collections.WorkspaceSet([backboneFixtures.workspace()]);
                this.result = Handlebars.helpers.usedInWorkspaces(this.workspaceList, this.contextObject).toString();
            });
            itIncludesTheFoundInWorkspaceInformation();

            it("should not indicate there are any other workspaces", function () {
                expect($(this.result).find('a').length).toBe(1);
            });

            it("does not modify the contexObject", function () {
                expect(this.contextObject.get('workspaceId')).toBeUndefined();
            });
        });

        context("when there are exactly 2 'found in' workspaces", function () {
            beforeEach(function () {
                this.workspaceList = new chorus.collections.WorkspaceSet([backboneFixtures.workspace(), backboneFixtures.workspace()]);
                this.result = Handlebars.helpers.usedInWorkspaces(this.workspaceList, this.contextObject).toString();
            });

            itIncludesTheFoundInWorkspaceInformation();

            it("should indicate there is 1 other workspace", function () {
                expect($(this.result)).toContainTranslation("workspaces_used_in.other_workspaces", {count:1});
            });
        });

        context("when there are exactly 3 'found in' workspaces", function () {
            beforeEach(function () {
                this.workspaceList = new chorus.collections.WorkspaceSet([backboneFixtures.workspace(), backboneFixtures.workspace(), backboneFixtures.workspace()]);
                this.result = Handlebars.helpers.usedInWorkspaces(this.workspaceList, this.contextObject).toString();
            });

            itIncludesTheFoundInWorkspaceInformation();

            it("should indicate there is 2 other workspaces", function () {
                expect($(this.result)).toContainTranslation("workspaces_used_in.other_workspaces", {count:2});
            });

            it("includes a menu to the other workspaces", function () {
                expect($(this.result).find("a.open_other_menu")).toExist();
                expect($(this.result).find(".other_menu li").length).toBe(2);
                var workspace = this.workspaceList.at(1);
                expect($(this.result).find(".other_menu li a:eq(0)")).toHaveAttr('href', '#/' + workspace.get('id') + '/contextObject');
                expect($(this.result).find(".other_menu li a:eq(0)")).toContainText(workspace.get('name'));
            });
        });
    });
});
