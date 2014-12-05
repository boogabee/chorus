describe("chorus.views.DataSourceConfigurationDetails", function() {
    context("hdfs data source", function() {
        beforeEach(function() {
            this.dataSource = backboneFixtures.hdfsDataSource({
                jobTrackerHost: 'foobar',
                jobTrackerPort: '1234'
            });
            this.view = new chorus.views.DataSourceConfigurationDetails({model: this.dataSource});
        });

        it("should display the job tracker host and port for a hdfs (if they exist)", function() {
            this.view.render();
            expect(this.view.$(".job_tracker_host")).toContainText('foobar');
            expect(this.view.$(".job_tracker_port")).toContainText('1234');
        });

        it("should not display the job tracker host and port for a hdfs (if they don't exist)", function() {
            this.dataSource.set('jobTrackerHost', null);
            this.dataSource.set('jobTrackerPort', null);
            this.view.render();
            expect(this.view.$(".job_tracker_host")).not.toExist();
            expect(this.view.$(".job_tracker_port")).not.toExist();
        });

        it("should display the proper translation for the host field", function() {
            this.view.render();
            expect(this.view.$('.host_label').text()).toContainTranslation("data_sources.sidebar.hadoop_host");
        });

    });

    context("greenplum/oracle data source", function() {
        beforeEach(function() {
            this.dataSource = backboneFixtures.gpdbDataSource();
            this.view = new chorus.views.DataSourceConfigurationDetails({model: this.dataSource});
        });

        it("should display the properly translation for the host field", function() {
            this.view.render();
            expect(this.view.$('.host_label').text()).toContainTranslation("data_sources.sidebar.host");
        });
    });
});
