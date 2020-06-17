import { h, render } from 'preact';
import { getUserDataAndCsrfToken } from '../chat/util';
import ArticleForm from '../article-form/articleForm';

HTMLDocument.prototype.ready = new Promise((resolve) => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

function loadForm() {
  getUserDataAndCsrfToken().then(({ currentUser, csrfToken }) => {
    window.currentUser = currentUser;
    window.csrfToken = csrfToken;

    const root = document.getElementById('js-article-form');
    const { article, organizations, version, logoSvg } = root.dataset;

    render(
      <ArticleForm
        article={article}
        organizations={organizations}
        version={version}
        logoSvg={logoSvg}
      />,
      root,
      root.firstElementChild,
    );
  });
}

/**
 * A function to hide an active broadcast if it exists
 * by removing a `broadcast-visible` class from it.
 *
 * @function hideActiveBroadcast
 */
function hideActiveBroadcast() {
  const broadcast = document.getElementById('active-broadcast');

  if (broadcast) {
    broadcast.classList.remove('broadcast-visible');
  }
}

document.ready.then(() => {
  hideActiveBroadcast();
  loadForm();
  window.InstantClick.on('change', () => {
    if (document.getElementById('article-form')) {
      loadForm();
    }
  });
});
