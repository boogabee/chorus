describe('chorus.models.DataSource', function() {
    beforeEach(function() {
            this.model = new chorus.models.DataSource({id: 1, owner: backboneFixtures.user()});
        }
    );

    it("has the right url", function() {
        expect(this.model.url()).toHaveUrlPath('/data_sources/1');

        this.model.unset("id", { silent: true });
        expect(this.model.url()).toHaveUrlPath('/data_sources/');
    });

    describe('#canHaveIndividualAccounts', function(){
        it('is true for greenplum data sources', function(){
            var gpdbDataSource = backboneFixtures.gpdbDataSource();
            expect(gpdbDataSource.canHaveIndividualAccounts()).toBeTruthy();
        });

        it('is true for oracle data sources', function(){
            var oracleDataSource = backboneFixtures.gpdbDataSource();
            expect(oracleDataSource.canHaveIndividualAccounts()).toBeTruthy();
        });
    });

    describe('#isShared', function(){
        it('returns true if the data source is marked as shared', function(){
            var shared = new chorus.models.DataSource({shared: true});
            expect(shared.isShared()).toBeTruthy();
            var unshared = new chorus.models.DataSource();
            expect(unshared.isShared()).toBeFalsy();
        });
    });

    describe('#isGreenplum', function(){
        it('returns true iff the data source is greenplum', function(){
            var gpdb = new chorus.models.DataSource({entityType: 'gpdb_data_source'});
            expect(gpdb.isGreenplum()).toBeTruthy();
            var oracle = new chorus.models.DataSource({entityType: 'oracle_data_source'});
            expect(oracle.isGreenplum()).toBeFalsy();
            var jdbc = new chorus.models.DataSource({entityType: 'jdbc_data_source'});
            expect(jdbc.isGreenplum()).toBeFalsy();
        });
    });

    describe('#isJdbc', function() {
        it('returns true iff the data source is jdbc', function(){
            var gpdb = new chorus.models.DataSource({entityType: 'gpdb_data_source'});
            expect(gpdb.isJdbc()).toBeFalsy();
            var oracle = new chorus.models.DataSource({entityType: 'oracle_data_source'});
            expect(oracle.isJdbc()).toBeFalsy();
            var jdbc = new chorus.models.DataSource({entityType: 'jdbc_data_source'});
            expect(jdbc.isJdbc()).toBeTruthy();
        });
    });

    describe("#accountForUser", function() {
        beforeEach(function() {
            this.user = backboneFixtures.user();
            this.model.set(backboneFixtures.gpdbDataSource().attributes);
            this.account = this.model.accountForUser(this.user);
        });

        it("returns an DataSourceAccount", function() {
            expect(this.account).toBeA(chorus.models.DataSourceAccount);
        });

        it("sets the data source id", function() {
            expect(this.account.get("dataSourceId")).toBe(this.model.get("id"));
        });

        it("sets the user id based on the given user", function() {
            expect(this.account.get("userId")).toBe(this.user.get("id"));
        });
    });

    describe("#accountForCurrentUser", function() {
        beforeEach(function() {
            this.model.set(backboneFixtures.gpdbDataSource().attributes);
            this.currentUser = backboneFixtures.user();
            setLoggedInUser(this.currentUser.attributes);
            this.model.set(backboneFixtures.gpdbDataSource().attributes);
        });

        it("memoizes", function() {
            var account = this.model.accountForCurrentUser();
            expect(account).toBe(this.model.accountForCurrentUser());
        });

        context("when the account is destroyed", function() {
            it("un-memoizes the account", function() {
                var previousAccount = this.model.accountForCurrentUser();
                previousAccount.trigger("destroy");

                var account = this.model.accountForCurrentUser();
                expect(account).not.toBe(previousAccount);
            });

            it("triggers 'change' on the data source", function() {
                spyOnEvent(this.model, 'change');
                this.model.accountForCurrentUser().trigger("destroy");
                expect("change").toHaveBeenTriggeredOn(this.model);
            });
        });
    });

    describe("#accountForOwner", function() {
        beforeEach(function() {
            this.model.set(backboneFixtures.gpdbDataSource().attributes);

            var owner = this.owner = this.model.owner();
            this.accounts = backboneFixtures.dataSourceAccountSet();
            this.accounts.each(function(account) {
                account.set({
                    owner: {
                        id: owner.id + 1
                    }
                });
            });

            this.accounts.models[1].set({owner: this.owner.attributes});
            spyOn(this.model, "accounts").andReturn(this.accounts);
        });

        it("returns the account for the owner", function() {
            expect(this.model.accountForOwner()).toBeA(chorus.models.DataSourceAccount);
            expect(this.model.accountForOwner()).toBe(this.accounts.models[1]);
        });
    });

    describe("#accounts", function() {
        beforeEach(function() {
            this.model.set(backboneFixtures.gpdbDataSource().attributes);

            this.dataSourceAccounts = this.model.accounts();
        });

        it("returns an DataSourceAccountSet", function() {
            expect(this.dataSourceAccounts).toBeA(chorus.collections.DataSourceAccountSet);
        });

        it("sets the data source id", function() {
            expect(this.dataSourceAccounts.attributes.dataSourceId).toBe(this.model.get('id'));
        });

        it("memoizes", function() {
            expect(this.dataSourceAccounts).toBe(this.model.accounts());
        });
    });

    describe("#usage", function() {
        beforeEach(function() {
            this.model.set(backboneFixtures.gpdbDataSource().attributes);

            this.dataSourceUsage = this.model.usage();
        });

        it("returns an DataSourceUsage object", function() {
            expect(this.dataSourceUsage).toBeA(chorus.models.DataSourceUsage);
        });

        it("sets the data source id", function() {
            expect(this.dataSourceUsage.attributes.dataSourceId).toBe(this.model.get('id'));
        });

        it("memoizes", function() {
            expect(this.dataSourceUsage).toBe(this.model.usage());
        });

        context("when the data source is Oracle", function() {
            it('returns null', function() {
                this.model = backboneFixtures.oracleDataSource();
                expect(this.model.usage()).toBeNull();
            });
        });

        context("when the data source is Jdbc", function() {
            it('returns null', function() {
                this.model = backboneFixtures.jdbcDataSource();
                expect(this.model.usage()).toBeNull();
            });
        });

        context("when the data source is Postgres", function() {
            it("returns an DataSourceUsage object", function() {
                this.model = backboneFixtures.pgDataSource();
                expect(this.model.usage()).toBeA(chorus.models.DataSourceUsage);
            });
        });
    });

    describe("#hasWorkspaceUsageInfo", function() {
        it("returns true when the data source usage is loaded", function() {
            this.model.usage().set({workspaces: []});
            expect(this.model.hasWorkspaceUsageInfo()).toBeTruthy();
        });

        it('returns false when the data source usage is not loaded', function() {
            this.model.usage().unset("workspaces");
            expect(this.model.hasWorkspaceUsageInfo()).toBeFalsy();
        });
    });

    describe("#sharing", function() {
        it("returns a data source sharing model", function() {
            expect(this.model.sharing().get("dataSourceId")).toBe(this.model.get("id"));
        });

        it("caches the sharing model", function() {
            var originalModel = this.model.sharing();
            expect(this.model.sharing()).toBe(originalModel);
        });
    });

    describe("#sharedAccountDetails", function() {
        beforeEach(function() {
            this.owner = this.model.owner();
            this.accounts = backboneFixtures.dataSourceAccountSet();
            this.accounts.models[1].set({owner: this.owner.attributes});
            spyOn(this.model, "accounts").andReturn(this.accounts);
        });

        it("returns the account name of the user who owns the data source and shared it", function() {
            this.user = backboneFixtures.user();
            this.account = this.model.accountForUser(this.user);
            expect(this.model.sharedAccountDetails()).toBe(this.model.accountForOwner().get("dbUsername"));
        });
    });
});
