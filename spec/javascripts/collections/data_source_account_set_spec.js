describe("chorus.collections.DataSourceAccountSet", function() {
    beforeEach(function() {
        this.accountSet = new chorus.collections.DataSourceAccountSet([], {dataSourceId: '1'});
    });

    describe("#users", function() {
        beforeEach(function() {
            this.accountSet.reset([
                backboneFixtures.dataSourceAccount({ owner: { id: '1', firstName: 'barnie', lastName: 'rubble' } }),
                backboneFixtures.dataSourceAccount({ owner: { id: '2', firstName: 'fred', lastName: 'flinstone' } })
            ]);
            this.users = this.accountSet.users();
        });

        it("returns an array of users", function() {
            expect(this.users.length).toBe(2);
        });

        it("builds user models with the 'user' attribute of the accounts", function() {
            expect(this.users[0].get("id")).toBe("2");
            expect(this.users[0].get("firstName")).toBe("fred");
            expect(this.users[0].get("lastName")).toBe("flinstone");

            expect(this.users[1].get("id")).toBe("1");
            expect(this.users[1].get("firstName")).toBe("barnie");
            expect(this.users[1].get("lastName")).toBe("rubble");
        });

        context("when there are no models in the collection", function() {
            beforeEach(function() {
                this.accountSet.reset();
                this.users = this.accountSet.users();
            });

            it("returns an empty array", function() {
                expect(this.users.length).toBe(0);
            });
        });
    });

    describe("url", function() {
        it("fetches from the correct endpoint", function() {
            this.accountSet.fetch();
            var accountFetch = this.server.lastFetchFor(this.accountSet);
            expect(accountFetch.url).toContain('/data_sources/1/members');
        });
    });

    describe("sort", function() {
        beforeEach(function() {
            this.accountSet.reset([
                backboneFixtures.dataSourceAccount({ owner: { firstName: 'fred', lastName: 'zzz' } }),
                backboneFixtures.dataSourceAccount({ owner: { firstName: 'barnie', lastName: 'zzz' } }),
                backboneFixtures.dataSourceAccount({ owner: { firstName: 'sammy', lastName: 'aaa' } })
            ]);
        });
        it("sorts by last name, and first name", function() {
            var userNames = this.accountSet.map(function(account) {
                return account.user().get('firstName');
            });
            expect(userNames).toEqual(['sammy', 'barnie', 'fred']);
        });
    });

    describe("persistedAccountCount", function() {
        context("when all of the accounts are persisted", function() {
            beforeEach(function() {
                this.accountSet.reset([
                    backboneFixtures.dataSourceAccount({ owner: { id: '1', firstName: 'barnie', lastName: 'rubble' } }),
                    backboneFixtures.dataSourceAccount({ owner: { id: '2', firstName: 'fred', lastName: 'flinstone' } })
                ]);
            });

            it("should be the full length", function() {
                expect(this.accountSet.persistedAccountCount()).toEqual(2);
            });
        });

        context("when some of the accounts are not persisted", function() {
            beforeEach(function() {
                this.accountSet.reset([
                    backboneFixtures.dataSourceAccount({ owner: { id: '1', firstName: 'barnie', lastName: 'rubble' } }),
                    backboneFixtures.dataSourceAccount({ owner: { id: '2', firstName: 'fred', lastName: 'flinstone' } }),
                    backboneFixtures.dataSourceAccount({ id: null, owner: { id: '3', firstName: 'wilma', lastName: 'flinstone' } })
                ]);
            });

            it("should not include non-persisted accounts", function() {
                expect(this.accountSet.persistedAccountCount()).toEqual(2);
            });
        });

        context("when none of the accounts are persisted", function() {
            beforeEach(function() {
                this.accountSet.reset([
                    backboneFixtures.dataSourceAccount({ id: null, owner: { id: '1', firstName: 'barnie', lastName: 'rubble' } }),
                    backboneFixtures.dataSourceAccount({ id: null, owner: { id: '2', firstName: 'fred', lastName: 'flinstone' } }),
                    backboneFixtures.dataSourceAccount({ id: null, owner: { id: '3', firstName: 'wilma', lastName: 'flinstone' } })
                ]);
            });

            it("should not include non-persisted accounts", function() {
                expect(this.accountSet.persistedAccountCount()).toEqual(0);
            });
        });
    });
});
