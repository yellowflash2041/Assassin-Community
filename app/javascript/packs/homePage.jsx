import { h, render } from 'preact';
import { TagsFollowed } from '../leftSidebar/TagsFollowed';

/* global userData */
// This logic is similar to that in initScrolling.js.erb
const frontPageFeedPathNames = new Map([
  ['/', ''],
  ['/top/week', 'week'],
  ['/top/month', 'month'],
  ['/top/year', 'year'],
  ['/top/infinity', 'infinity'],
  ['/latest', 'latest'],
]);

/**
 * Renders tags followed in the left side bar of the homepage.
 *
 * @param {HTMLElement} tagsFollowedContainer DOM element to render tags followed.
 * @param {object} user The currently logged on user, null if not logged on.
 */

function renderTagsFollowed(user = userData()) {
  const tagsFollowedContainer = document.getElementById(
    'sidebar-nav-followed-tags',
  );
  if (!tagsFollowedContainer) {
    // Not on the homepage, so nothing to do.
    return false;
  }
  if (user === null || document.getElementById('followed-tags-wrapper')) {
    return;
  }

  // Only render if a user is logged on.
  const { followed_tags } = user; // eslint-disable-line camelcase
  const followedTags = JSON.parse(followed_tags);

  // This should be done server-side potentially
  // sort tags by descending weight, descending popularity and name
  followedTags.sort((tagA, tagB) => {
    return (
      tagB.points - tagA.points ||
      tagB.hotness_score - tagA.hotness_score ||
      tagA.name.localeCompare(tagB.name)
    );
  });

  render(
    <TagsFollowed tags={followedTags} />,
    tagsFollowedContainer,
    tagsFollowedContainer.firstElementChild,
  );
}

function renderSidebar() {
  const sidebarContainer = document.getElementById(
    'sidebar-wrapper-right',
  );

  // If the screen's width is less than 1024px we don't need this extra data.
  if (sidebarContainer && screen.width > 1023 && window.location.pathname === '/') {
    window.fetch('/sidebars/home')
    .then(res => res.text())
    .then(response => {
      sidebarContainer.innerHTML = response;
    });
  }
}


const feedTimeFrame = frontPageFeedPathNames.get(window.location.pathname);

if (!document.getElementById('featured-story-marker')) {
  const waitingForDataLoad = setInterval(function dataLoadedCheck() {
    const { user = null, userStatus } = document.body.dataset;
    if (userStatus === 'logged-out') {
      return;
    }

    if (userStatus === 'logged-in' && user !== null) {
      clearInterval(waitingForDataLoad);
      if (document.getElementById('rendered-article-feed')) {
        return;
      }
      import('./homePageFeed').then(({ renderFeed }) => {
        // We have user data, render followed tags.
        renderFeed(feedTimeFrame);

        InstantClick.on('change', () => {
          const { userStatus: currentUserStatus } = document.body.dataset;

          if (currentUserStatus === 'logged-out') {
            return;
          }

          const url = new URL(window.location);
          const changedFeedTimeFrame = frontPageFeedPathNames.get(url.pathname);

          if (!frontPageFeedPathNames.has(url.pathname)) {
            return;
          }

          renderFeed(changedFeedTimeFrame);
        });
      });

      renderTagsFollowed();
      renderSidebar();
    }
  }, 2);
}

InstantClick.on('change', () => {
  if (document.body.dataset.userStatus !== 'logged-in') {
    // Nothing to do, the user is not logged on.
    return false;
  }

  renderTagsFollowed();
  renderSidebar();
});
InstantClick.init();
