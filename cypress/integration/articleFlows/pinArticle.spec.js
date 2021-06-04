describe('Pin an article - Anonymous user', () => {
  beforeEach(() => {
    cy.testSetup();

    cy.visit('/');
  });

  it('should not see the Pin Post button', () => {
    cy.findAllByRole('heading', { name: 'Test article' }).first().click();

    cy.findByRole('main')
      .findByRole('button', { name: 'Pin Post' })
      .should('not.exist');
  });
});

describe('Pin an article - Non admin user', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV1User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.createArticle({
          title: 'Test Article',
          tags: ['beginner', 'ruby', 'go'],
          content: `This is a test article's contents.`,
          published: true,
        }).then((response) => {
          cy.visit(response.body.current_state_path);
        });
      });
    });
  });

  it('should not see the Pin Post button', () => {
    cy.findByRole('main')
      .findByRole('button', { name: 'Pin Post' })
      .should('not.exist');
  });
});

describe('Pin an article - Admin User', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.createArticle({
          title: 'Test Article',
          tags: ['beginner', 'ruby', 'go'],
          content: `This is a test article's contents.`,
          published: true,
        }).then((response) => {
          cy.visit(response.body.current_state_path);
        });
      });
    });
  });

  it('should pin a post', () => {
    cy.findByRole('main').within(() => {
      cy.findAllByRole('button', { name: 'Pin Post' }).first().click();

      // check the button has changed to "Unpin Post"
      cy.findAllByRole('button', { name: 'Unpin Post' }).first();
    });

    cy.visit('/');

    cy.findByRole('main').findByTestId('pinned-article').should('be.visible');
  });

  it('should unpin a post', () => {
    cy.findByRole('main').within(() => {
      cy.findAllByRole('button', { name: 'Pin Post' }).first().click();
      cy.findAllByRole('button', { name: 'Unpin Post' }).first().click();
      cy.findAllByRole('button', { name: 'Pin Post' }).first();
    });

    cy.visit('/');

    cy.findByRole('main').findByTestId('pinned-article').should('not.exist');
  });

  it('should not add the "Pin Post" button to a draft article', () => {
    cy.findByRole('main')
      .findAllByRole('button', { name: 'Pin Post' })
      .first()
      .click();

    cy.createArticle({
      title: 'Test Article 2',
      tags: ['beginner', 'ruby', 'go'],
      content: `This is a test article's contents.`,
      published: false,
    }).then((response) => {
      cy.visit(response.body.current_state_path);
    });

    cy.findByRole('main')
      .findByRole('button', { name: 'Pin Post' })
      .should('not.exist');
  });

  it('should not add the "Pin Post" button to the non currently pinned article', () => {
    cy.findByRole('main')
      .findAllByRole('button', { name: 'Pin Post' })
      .first()
      .click();

    cy.createArticle({
      title: 'Test Article 2',
      tags: ['beginner', 'ruby', 'go'],
      content: `This is a test article's contents.`,
      published: true,
    }).then((response) => {
      cy.visit(response.body.current_state_path);
    });

    cy.findByRole('main')
      .findByRole('button', { name: 'Pin Post' })
      .should('not.exist');
  });

  it('should allow to pin another post after the current pinned post is deleted', () => {
    cy.findByRole('main').within(() => {
      cy.findAllByRole('button', { name: 'Pin Post' }).first().click();
      cy.findAllByRole('link', { name: 'Manage' }).first().click();
    });

    cy.findByRole('heading', { name: 'Tools:' });

    cy.findByRole('main')
      .findAllByRole('link', { name: 'Delete' })
      .first()
      .click();

    cy.findByRole('heading', {
      name: 'Are you sure you want to delete this article?',
    });

    cy.findByRole('main')
      .findAllByRole('button', { name: 'Delete' })
      .first()
      .click();

    cy.visit('/');

    cy.createArticle({
      title: 'Another Article',
      tags: ['beginner', 'ruby', 'go'],
      content: `This is a test article's contents.`,
      published: true,
    }).then((response) => {
      cy.visit(response.body.current_state_path);
    });

    cy.findByRole('main')
      .findAllByRole('button', { name: 'Pin Post' })
      .first()
      .should('exist');
  });

  it('should allow to pin another post after the current pinned post is unpublished', () => {
    cy.findByRole('main').within(() => {
      cy.findAllByRole('button', { name: 'Pin Post' }).first().click();
      cy.findAllByRole('link', { name: 'Manage' }).first().click();
    });

    cy.findByRole('main')
      .findAllByRole('link', { name: 'Delete' })
      .first()
      .click();

    cy.findByRole('main')
      .findAllByRole('link', { name: 'Unpublish' })
      .first()
      .click();

    cy.findByRole('main').within(() => {
      cy.findAllByTitle(/^Post options$/i)
        .first()
        .click();
      cy.findAllByRole('button', { name: 'Unpublish post' }).first().click();
    });

    cy.createArticle({
      title: 'Another Article',
      tags: ['beginner', 'ruby', 'go'],
      content: `This is a test article's contents.`,
      published: true,
    }).then((response) => {
      cy.visit(response.body.current_state_path);
    });

    cy.findByRole('main')
      .findAllByRole('button', { name: 'Pin Post' })
      .first()
      .should('exist');
  });
});
