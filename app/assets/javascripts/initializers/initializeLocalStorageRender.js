function initializeLocalStorageRender() {
  try {
    var userData = browserStoreCache("get");
    if (userData) {
      document.getElementsByTagName('body')[0].dataset.user = userData;
      initializeBaseUserData();
      initializeReadingListIcons();
      initializeAllFollowButts();
      initializeReadingListPage();
      initializeSponsorshipVisibility();
    }
  }
  catch(err) {
      browserStoreCache("remove");
  }
}