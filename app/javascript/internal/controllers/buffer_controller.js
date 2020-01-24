import { Controller } from 'stimulus';

export default class BufferController extends Controller {
  static targets = ['header'];

  tagBufferUpdateConfirmed() {
    this.headerTarget.innerHTML +=
      '<span class="ml-2 badge badge-success">Confirm</span>';
  }

  tagBufferUpdateDismissed() {
    this.headerTarget.innerHTML +=
      '<span class="ml-2 badge badge-danger">Dismiss</span>';
  }

  highlightElement() {
    this.element.classList.add('highlighted-bg', 'highlighted-border');
    setTimeout(() => {
      this.element.classList.remove('highlighted-bg');
    }, 350);
  }

  get bufferUpdateId() {
    return parseInt(this.data.get('id'), 10);
  }

  set bufferUpdateId(value) {
    this.data.set('id', value);
  }
}
