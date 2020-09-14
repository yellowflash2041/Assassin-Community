import { h, render } from 'preact';
import { getUserDataAndCsrfToken } from '../chat/util';
import ArticleForm from '../article-form/articleForm';
import { Snackbar } from '../Snackbar';

HTMLDocument.prototype.ready = new Promise((resolve) => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

function loadForm() {
  // The Snackbar for the article page
  const snackZone = document.getElementById('snack-zone');

  if (snackZone) {
    render(<Snackbar lifespan="3" />, snackZone);
  }

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

document.ready.then(() => {
  loadForm();
  window.InstantClick.on('change', () => {
    if (document.getElementById('article-form')) {
      loadForm();
    }
  });
});
