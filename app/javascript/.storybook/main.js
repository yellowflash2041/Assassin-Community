const path = require('path');
const marked = require('marked');
const renderer = new marked.Renderer();

module.exports = {
  stories: ['../**/__stories__/*.stories.jsx'],
  addons: [
    '@storybook/addon-knobs',
    '@storybook/addon-actions',
    '@storybook/addon-links',
    '@storybook/addon-a11y/register',
    '@storybook/addon-notes/register-panel',
  ],
  webpackFinal: async (config, { configType }) => {
    config.module.rules.push({
      test: /\.scss$/,
      use: [
        'style-loader',
        'css-loader',
        {
          loader: 'sass-loader',
          options: {
            // The injected environment variable is so that SASS mixins/functions can handle
            // generating correct CSS for Sprockets or webpack when in Storybook.
            // an example of it's usage can be found in /app/assets/stylesheets/_mixins.scss
            additionalData: '$environment: "storybook";',
          },
        },
      ],
      include: path.resolve(__dirname, '../../'),
    });

    config.module.rules.push({
      test: /\.md$/,
      use: [
        {
          loader: 'markdown-loader',
          options: {
            pedantic: true,
            renderer,
          },
        },
      ],
    });

    config.resolve = {
      ...config.resolve,
      extensions: [...config.resolve.extensions, '.scss'],
      alias: {
        ...config.resolve.alias,
        '@crayons': path.resolve(__dirname, '../crayons'),
      },
    };

    return config;
  },
};
