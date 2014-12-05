chorus.handlebarsHelpers.user = {
    ifAdmin: function(block) {
        var user = chorus && chorus.session && chorus.session.user();
        if (user && user.get("admin")) {
            return block.fn(this);
        } else {
            return block.inverse(this);
        }
    },

    ifAdminOr: function(flag, block) {
        var user = chorus && chorus.session && chorus.session.user();
        if ((user && user.get("admin")) || flag) {
            return block.fn(this);
        } else {
            return block.inverse(this);
        }
    },

    ifCurrentUserNameIs: function(username, block) {
        var user = chorus && chorus.session && chorus.session.user();
        if (user && user.get("username") === username) {
            return block.fn(this);
        } else if (block.inverse) {
            return block.inverse(this);
        }
    },

    currentUserName: function() {
        return chorus.session.get("username");
    },

    displayNameFromPerson: function(person) {
        return [person.firstName, person.lastName].join(' ');
    },

    userProfileLink: function(user) {
        return Handlebars.helpers.linkTo(user.showUrl(), user.displayName(), {'class': 'user'});
    }
};

_.each(chorus.handlebarsHelpers.user, function(helper, name) {
    Handlebars.registerHelper(name, helper);
});