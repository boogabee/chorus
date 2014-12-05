moment.fn.forceZone = function (newZone) {
    var originalOffset = this.zone();
    this.zone(newZone);
    var offsetChange = this.zone() - originalOffset;
    this.add(offsetChange, 'minutes');
    return this;
};