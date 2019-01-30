function initializeBaseUserData() {
  var user = userData();
  var userProfileLinkHTML =
    '<a href="/' +
    user.username +
    '" id="first-nav-link"><div class="option prime-option">@' +
    user.username +
    '</div></a>';
  document.getElementById(
    'user-profile-link-placeholder',
  ).innerHTML = userProfileLinkHTML;
  document.getElementById('nav-profile-image').src = user.profile_image_90;
  initializeUserSidebar(user);
  addRelevantButtonsToArticle(user);
}

function initializeUserSidebar(user) {
  if (!document.getElementById('sidebar-nav')) return;
  initializeUserProfileContent(user);
  var tagHTML = '';
  var followedTags = JSON.parse(user.followed_tags);
  document.getElementById('tag-separator').innerHTML =
    followedTags.length === 0
      ? 'Follow tags to improve your feed'
      : 'Other Popular Tags';

  // sort tags by descending weigth, descending popularity and name
  followedTags.sort(function(tagA, tagB) {
    return (
      tagB.points - tagA.points ||
      tagB.hotness_score - tagA.hotness_score ||
      tagA.name.localeCompare(tagB.name)
    );
  });

  followedTags.forEach(function(t) {
    var element = document.getElementById('default-sidebar-element-' + t.name);
    tagHTML +=
      t.points > 0.0
        ? '<div class="sidebar-nav-element" id="sidebar-element-' +
          t.name +
          '">' +
          '<a class="sidebar-nav-link" href="/t/' +
          t.name +
          '">' +
          '<span class="sidebar-nav-tag-text">#' +
          t.name +
          '</span>' +
          '</a>' +
          '</div>'
        : '';
    if (element) element.remove();
  });
  document.getElementById('sidebar-nav-followed-tags').innerHTML = tagHTML;
  document.getElementById('sidebar-nav-default-tags').classList.add('showing');
}

function initializeUserProfileContent(user) {
  document.getElementById('sidebar-profile-pic').innerHTML =
    '<img alt="" class="sidebar-profile-pic-img" src="' +
    user.profile_image_90 +
    '" />';
  document.getElementById('sidebar-profile-name').innerHTML = filterXSS(
    user.name,
  );
  document.getElementById('sidebar-profile-username').innerHTML =
    '@' + user.username;
  document.getElementById('sidebar-profile-snapshot-inner').href =
    '/' + user.username;
}

function addRelevantButtonsToArticle(user) {
  var articleContainer = document.getElementById('article-show-container');
  if (articleContainer) {
    if (parseInt(articleContainer.dataset.authorId) == user.id) {
      document.getElementById('action-space').innerHTML =
        '<a href="' +
        articleContainer.dataset.path +
        '/edit" rel="nofollow">EDIT <span class="post-word">POST</span></a>';
    } else if (user.trusted) {
      document.getElementById('action-space').innerHTML =
        '<a href="' +
        articleContainer.dataset.path +
        '/mod" rel="nofollow">MODERATE <span class="post-word">POST</span></a>';
    }
  }
  var commentsContainer = document.getElementById('comments-container');
  if (commentsContainer) {
    var settingsButts = document.getElementsByClassName('comment-actions');

    for (var i = 0; i < settingsButts.length; i++) {
      var butt = settingsButts[i];
      if (parseInt(butt.dataset.userId) === user.id) {
        butt.className = 'comment-actions';
        butt.style.display = 'inline-block';
      }
    }

    if (user.trusted) {
      var modButts = document.getElementsByClassName('mod-actions');
      for (var i = 0; i < modButts.length; i++) {
        var butt = modButts[i];
        butt.className = 'mod-actions';
        butt.style.display = 'inline-block';
      }
    }
  }
}
