import { h } from 'preact';

const OnboardingWelcomeThread = () => {
  const wrapInYellow = message => (
    <strong className="yellow">{message}</strong>
  );

  return (
    <div class="onboarding-final-message">
      <p>Software is driven by community.</p>
      <p>Don't hesitate to find a discussion and jump right in.</p>
      <p><em class="green">Everyone is welcome!</em></p>
    </div>
  );
};

export default OnboardingWelcomeThread;
