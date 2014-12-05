chorus.dateFormatForApi = d3.time.format.utc("%Y-%m-%dT%H:%M:%SZ");

chorus.parseDateFromApi = function(str) {
    return str && chorus.dateFormatForApi.parse(str);
};
