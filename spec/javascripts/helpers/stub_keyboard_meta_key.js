function stubKeyboardMetaKey() {
    beforeEach(function() {
        this.oldHotKeyMeta = chorus.hotKeyMeta;
        chorus.hotKeyMeta = 'ctrl';
    });

    afterEach(function() {
        chorus.hotKeyMeta = this.oldHotKeyMeta;
    });
}