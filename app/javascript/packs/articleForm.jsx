import { h, render } from 'preact';
import { getUserDataAndCsrfToken } from '../chat/util';
import ArticleForm from '../article-form/articleForm';

HTMLDocument.prototype.ready = new Promise(resolve => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

document.ready.then(
  getUserDataAndCsrfToken().then(currentUser => {
    window.currentUser = currentUser;
    const root = document.getElementById('article-form');
    window.csrfToken = document.querySelector(
      "meta[name='csrf-token']",
    ).content;
    render(
      <ArticleForm
        article={document.getElementById('article-form').dataset.article}
        organization={document.getElementById('article-form').dataset.organization}
       />,
      root,
      root.firstElementChild
    );
  }),
);
