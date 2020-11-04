import { Controller } from 'stimulus';
import adminModal from '../adminModal';

const recaptchaFields = document.querySelector('#recaptchaContainer');
const emailSigninAndLoginCheckbox = document.querySelector(
  '#email-signup-and-login-checkbox',
);
const emailAuthSettingsSection = document.querySelector(
  '#email-auth-settings-section',
);
const emailAuthModalTitle = 'Disable email address registration';
// TODO: Remove the sentence "You must update site config to save this action!"
// once we build more robust flow for Admin/Config
const emailAuthModalBody =
  '<p>If you disable email address as a registration option, people cannot create an account with their email address.</p><p>However, people who have already created an account using their email address can continue to login.</p><p><strong>Please update site config to save this action.</strong></p>';

export default class ConfigController extends Controller {
  static targets = [
    'authenticationProviders',
    'collectiveNoun',
    'configModalAnchor',
    'emailAuthSettingsBtn',
    'enabledIndicator',
    'inviteOnlyMode',
    'requireCaptchaForEmailPasswordRegistration',
  ];

  disableTargetField(event) {
    const targetElementName = event.target.dataset.disableTarget;
    const targetElement = this[`${targetElementName}Target`];
    const newValue = event.target.checked;
    targetElement.disabled = newValue;

    // Disable the button generated by ERB for select tags
    if (targetElement.nodeName === 'SELECT') {
      const snakeCaseName = targetElementName.replace(
        /[A-Z]/g,
        (letter) => `_${letter.toLowerCase()}`,
      );
      document.querySelector(
        `button[data-id=site_config_${snakeCaseName}]`,
      ).disabled = newValue;
    }
  }

  toggleGoogleRecaptchaFields() {
    if (this.requireCaptchaForEmailPasswordRegistrationTarget.checked) {
      recaptchaFields.classList.remove('hidden');
    } else {
      recaptchaFields.classList.add('hidden');
    }
  }

  enableOrEditEmailAuthSettings() {
    event.preventDefault();
    if (this.emailAuthSettingsBtnTarget.dataset.buttonText === 'enable') {
      emailSigninAndLoginCheckbox.checked = true;
      this.enabledIndicatorTarget.classList.add('flex', 'items-center');
      this.enabledIndicatorTarget.classList.remove('hidden');
    }
    this.emailAuthSettingsBtnTarget.classList.add('hidden');
    emailAuthSettingsSection.classList.remove('hidden');
  }

  hideEmailAuthSettings() {
    event.preventDefault();
    this.emailAuthSettingsBtnTarget.classList.remove('hidden');
    emailAuthSettingsSection.classList.add('hidden');
  }

  activateEmailAuthModal(event) {
    event.preventDefault();
    this.configModalAnchorTarget.innerHTML = adminModal(
      emailAuthModalTitle,
      emailAuthModalBody,
      'Confirm disable',
      'disableEmailAuthFromModal',
      'Cancel',
      'closeAdminConfigModal',
    );
    if (document.querySelector('.crayons-modal')) {
      document.body.style.height = '100vh';
      document.body.style.overflowY = 'hidden';
    }
  }

  closeAdminConfigModal() {
    this.configModalAnchorTarget.innerHTML = '';
    document.body.style.height = 'inherit';
    document.body.style.overflowY = 'inherit';
  }

  disableEmailAuthFromModal() {
    event.preventDefault();
    this.disableEmailAuth();
    this.closeAdminConfigModal();
  }

  disableEmailAuth() {
    event.preventDefault();
    emailSigninAndLoginCheckbox.checked = false;
    this.emailAuthSettingsBtnTarget.innerHTML = 'Enable';
    this.enabledIndicatorTarget.classList.remove('flex', 'items-center');
    this.enabledIndicatorTarget.classList.add('hidden');
    this.hideEmailAuthSettings();
  }
}
