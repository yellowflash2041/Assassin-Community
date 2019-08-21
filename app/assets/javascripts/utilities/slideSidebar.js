'use strict';

function slideSidebar(side, direction) {
  if (!document.getElementById('sidebar-wrapper-' + side)) {
    return;
  }
  if (direction === 'intoView') {
    document.getElementById('articles-list').classList.add('modal-open');
    document.getElementsByTagName('body')[0].classList.add('modal-open');
    document
      .getElementById('sidebar-wrapper-' + side)
      .classList.add('swiped-in');
    document
      .getElementById('articles-list')
      .addEventListener('touchmove', preventDefaultAction, false);
  } else {
    document.getElementById('articles-list').classList.remove('modal-open');
    document.getElementsByTagName('body')[0].classList.remove('modal-open');
    document
      .getElementById('sidebar-wrapper-' + side)
      .querySelector('.side-bar').scrollTop = 0;
    document
      .getElementById('sidebar-wrapper-' + side)
      .classList.remove('swiped-in');
    document
      .getElementById('articles-list')
      .removeEventListener('touchmove', preventDefaultAction, false);
  }
}
