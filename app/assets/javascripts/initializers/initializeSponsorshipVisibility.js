function initializeSponsorshipVisibility() {
  var el =
    document.getElementById('sponsorship-widget') ||
    document.getElementById('partner-content-display');
  var user = userData();
  if (el) {
    setTimeout(function() {
      if (window.ga) {
        if (document.querySelectorAll('[data-partner-seen]').length === 0) {
          ga('send', 'event', 'view', 'sponsor displayed on page', el.dataset.details, null);
          el.dataset.partnerSeen = 'true';
        }
      }
    }, 400);
  }
  if (el && user && user.display_sponsors) {
    el.classList.add('showing');
    listenForSponsorClick();
  } else if (el && user) {
    el.classList.remove('showing');
  } else if (el) {
    el.classList.add('showing');
    listenForSponsorClick();
  }
}

function listenForSponsorClick() {
  setTimeout(function() {
    if (window.ga) {
      var links = document.getElementsByClassName('partner-link');
      for (var i = 0; i < links.length; i++) {
        links[i].onclick = function(event) {
          if (event.target.classList.contains('follow-action-button')) {
            handleOptimisticButtRender(event.target);
            handleFollowButtPress(event.target);
          }
          ga('send', 'event', 'click', 'click sponsor link', event.target.dataset.details, null);
        };
      }
    }
  }, 400);
}
