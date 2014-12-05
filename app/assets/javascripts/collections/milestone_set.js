chorus.collections.MilestoneSet = chorus.collections.Base.extend({
    constructorName: "MilestoneSet",
    model: chorus.models.Milestone,
    urlTemplate: "workspaces/{{workspaceId}}/milestones"
});
