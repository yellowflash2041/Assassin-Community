module.exports = {
  extends: ['airbnb-base/legacy', 'prettier'],
  parserOptions: {
    ecmaVersion: 2018,
  },
  env: {
    browser: true,
  },
  plugins: ['ignore-erb'],
  rules: {
    'no-unused-vars': 'off',
    'vars-on-top': 'off',
  },
  globals: {
    getCsrfToken: false,
    sendFetch: false,
    preventDefaultAction: false,
    userData: false,
    ga: false, // Google Analytics
    handleOptimisticButtRender: false,
    handleFollowButtPress: false,
    browserStoreCache: false,
    initializeBaseUserData: false,
    initializeReadingListIcons: false,
    initializeAllFollowButts: false,
    initializeSponsorshipVisibility: false,
    ActiveXObject: false,
  },
};
