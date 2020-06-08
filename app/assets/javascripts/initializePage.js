/*
  global initializeLocalStorageRender, initializeStylesheetAppend, initializeBodyData,
  initializeAllChatButtons, initializeAllTagEditButtons, initializeUserFollowButts,
  initializeBaseTracking, initializeTouchDevice, initializeCommentsPage,
  initializeArticleDate, initializeArticleReactions, initNotifications,
  initializeCommentDate, initializeCommentDropdown, initializeSettings,
  initializeFooterMod, initializeCommentPreview, initializeAdditionalContentBoxes,
  initializeTimeFixer, initializeDashboardSort, initializePWAFunctionality,
  initializeEllipsisMenu, initializeArchivedPostFilter, initializeCreditsPage,
  initializeUserProfilePage, initializePodcastPlayback, initializeDrawerSliders,
  initializeHeroBannerClose, initializeOnboardingTaskCard, initScrolling,
  nextPage:writable, fetching:writable, done:writable, adClicked:writable,
  initializeSpecialNavigationFunctionality, initializeBroadcast
*/

function callInitializers() {
  initializeLocalStorageRender();
  initializeBodyData();

  var waitingForDataLoad = setInterval(function wait() {
    if (document.body.getAttribute('data-loaded') === 'true') {
      clearInterval(waitingForDataLoad);
      if (document.body.getAttribute('data-user-status') === 'logged-in') {
        initializeBaseUserData();
        initializeAllChatButtons();
        initializeAllTagEditButtons();
      }
      initializeBroadcast();
      initializeAllFollowButts();
      initializeUserFollowButts();
      initializeReadingListIcons();
      initializeSponsorshipVisibility();
      if (document.getElementById('sidebar-additional')) {
        document.getElementById('sidebar-additional').classList.add('showing');
      }
    }
  }, 1);

  initializeSpecialNavigationFunctionality();
  initializeBaseTracking();
  initializeTouchDevice();
  initializeCommentsPage();
  initializeArticleDate();
  initializeArticleReactions();
  initNotifications();
  initializeStylesheetAppend();
  initializeCommentDate();
  initializeCommentDropdown();
  initializeSettings();
  initializeFooterMod();
  initializeCommentPreview();
  initializeAdditionalContentBoxes();
  initializeTimeFixer();
  initializeDashboardSort();
  initializePWAFunctionality();
  initializeEllipsisMenu();
  initializeArchivedPostFilter();
  initializeCreditsPage();
  initializeUserProfilePage();
  initializePodcastPlayback();
  initializeDrawerSliders();
  initializeHeroBannerClose();
  initializeOnboardingTaskCard();

  function freezeScrolling(event) {
    event.preventDefault();
  }

  nextPage = 0;
  fetching = false;
  done = false;
  adClicked = false;
  setTimeout(function undone() {
    done = false;
  }, 300);
  if (!initScrolling.called) {
    initScrolling();
  }
}

function initializePage() {
  initializeLocalStorageRender();
  initializeStylesheetAppend();
  callInitializers();
}
