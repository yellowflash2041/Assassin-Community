import 'preact/devtools';
import { h, Component } from 'preact';
import linkState from 'linkstate';
import ImageUploadIcon from 'images/image-upload.svg';
import ThreeDotsIcon from 'images/three-dots.svg';
import { submitArticle, previewArticle } from './actions';
import BodyMarkdown from './elements/bodyMarkdown';
import BodyPreview from './elements/bodyPreview';
// import Description from './elements/description';
import PublishToggle from './elements/publishToggle';
import Notice from './elements/notice';
import Tags from './elements/tags';
import Title from './elements/title';
import MainImage from './elements/mainImage';
import ImageManagement from './elements/imageManagement';
import MoreConfig from './elements/moreConfig';
import OrgSettings from './elements/orgSettings';
import Errors from './elements/errors';

export default class ArticleForm extends Component {
  constructor(props) {
    super(props);
    this.article = JSON.parse(this.props.article);
    const organization = this.props.organization
      ? JSON.parse(this.props.organization)
      : null;

    this.url = window.location.href;

    this.state = {
      id: this.article.id || null,
      title: this.article.title || '',
      tagList: this.article.cached_tag_list || '',
      description: '',
      canonicalUrl: this.article.canonical_url || '',
      series: this.article.series || '',
      allSeries: this.article.all_series || [],
      bodyMarkdown: this.article.body_markdown || '',
      published: this.article.published || false,
      previewShowing: false,
      helpShowing: false,
      previewResponse: '',
      helpHTML: document.getElementById('editor-help-guide').innerHTML,
      submitting: false,
      editing: this.article.id != null,
      imageManagementShowing: false,
      moreConfigShowing: false,
      mainImage: this.article.main_image || null,
      organization,
      postUnderOrg: !!this.article.organization_id,
      errors: null,
      edited: false,
      version: this.props.version,
    };
  }

  componentDidMount() {
    const { version } = this.state
    const previousContent = JSON.parse(
      localStorage.getItem(`editor-${version}-${window.location.href}`),
    );
    if (previousContent && this.checkContentChanges(previousContent)) {
      this.setState({
        title: previousContent.title || '',
        tagList: previousContent.tagList || '',
        mainImage: previousContent.mainImage || null,
        bodyMarkdown: previousContent.bodyMarkdown || '',
        edited: true,
      });
    }

    window.addEventListener('beforeunload', this.localStoreContent);

    // const editor = document.getElementById('article_body_markdown');
    // const myCodeMirror = CodeMirror(editor, {
    //   mode: 'markdown',
    //   theme: 'material',
    //   highlightFormatting: true,
    // });
    // myCodeMirror.setSize('100%', '100%');
  }

  checkContentChanges = previousContent =>
    this.state.bodyMarkdown !== previousContent.bodyMarkdown ||
    this.state.title !== previousContent.title ||
    this.state.mainImage !== previousContent.mainImage ||
    this.state.tagList !== previousContent.tagList;

  localStoreContent = () => {
    const { version, title, tagList, mainImage, bodyMarkdown } = this.state
    localStorage.setItem(
      `editor-${version}-${this.url}`,
      JSON.stringify({
        title,
        tagList,
        mainImage,
        bodyMarkdown,
      }),
    );
  };

  toggleHelp = e => {
    e.preventDefault();
    window.scrollTo(0, 0);
    this.setState({
      helpShowing: !this.state.helpShowing,
      previewShowing: false,
    });
    setTimeout(function(){
      e.target.blur();
    },3)
  };

  fetchPreview = e => {
    e.preventDefault();
    if (this.state.previewShowing) {
      this.setState({
        previewShowing: false,
        helpShowing: false,
      });
    } else {
      previewArticle(
        this.state.bodyMarkdown,
        this.showPreview,
        this.failedPreview,
      );
    }
    setTimeout(function(){
      e.target.blur();
    },3)
  };

  toggleImageManagement = e => {
    e.preventDefault();
    this.setState({
      imageManagementShowing: !this.state.imageManagementShowing,
    });
  };

  toggleMoreConfig = e => {
    e.preventDefault();
    this.setState({
      moreConfigShowing: !this.state.moreConfigShowing,
    });
  };

  showPreview = response => {
    this.setState({
      previewShowing: true,
      helpShowing: false,
      previewResponse: response,
    });
  };

  toggleOrgPosting = e => {
    e.preventDefault();
    this.setState({ postUnderOrg: !this.state.postUnderOrg });
    setTimeout(function(){
      e.target.blur();
    },3)
  };

  failedPreview = response => {
    console.log(response);
  };

  handleConfigChange = e => {
    e.preventDefault();
    const newState = {};
    newState[e.target.name] = e.target.value;
    this.setState(newState);
  };

  handleMainImageUrlChange = payload => {
    this.setState({
      mainImage: payload.link,
      imageManagementShowing: false,
    });
  };

  removeLocalStorage = () => {
    const {version} = this.state
    localStorage.removeItem(`editor-${version}-${this.url}`);
    window.removeEventListener('beforeunload', this.localStoreContent);
  };

  onPublish = e => {
    e.preventDefault();
    this.setState({ submitting: true, published: true });
    const { state } = this;
    state.published = true;
    submitArticle(state, this.removeLocalStorage, this.handleArticleError);
  };

  onSaveDraft = e => {
    e.preventDefault();
    this.setState({ submitting: true, published: false });
    const { state } = this;
    state.published = false;
    submitArticle(state, this.removeLocalStorage, this.handleArticleError);
  };

  handleTitleKeyDown = e => {
    if (e.keyCode === 13) {
      e.preventDefault();
    }
  }

  handleBodyKeyDown = e => {

  }

  onClearChanges = e => {
    e.preventDefault();
    const revert = confirm(
      'Are you sure you want to revert to the previous save?',
    );
    if (!revert) return;
    this.setState({
      title: this.article.title || '',
      tagList: this.article.cached_tag_list || '',
      description: '',
      canonicalUrl: this.article.canonical_url || '',
      series: this.article.series || '',
      allSeries: this.article.all_series || [],
      bodyMarkdown: this.article.body_markdown || '',
      published: this.article.published || false,
      previewShowing: false,
      helpShowing: false,
      previewResponse: '',
      helpHTML: document.getElementById('editor-help-guide').innerHTML,
      submitting: false,
      editing: this.article.id != null,
      imageManagementShowing: false,
      moreConfigShowing: false,
      mainImage: this.article.main_image || null,
      errors: null,
      edited: false,
    });
  };

  handleArticleError = response => {
    window.scrollTo(0, 0);
    this.setState({
      errors: response,
      submitting: false,
    });
  };

  toggleEdit = () => {
    this.localStoreContent();
    const { edited } = this.state;
    if (edited) return;
    this.setState({
      edited: true,
    });
  };

  render() {
    // cover image url should asking for url OR providing option to upload an image
    const {
      title,
      tagList,
      bodyMarkdown,
      published,
      previewShowing,
      helpShowing,
      previewResponse,
      helpHTML,
      submitting,
      imageManagementShowing,
      moreConfigShowing,
      organization,
      postUnderOrg,
      mainImage,
      errors,
      version
    } = this.state;
    const notice = submitting ? <Notice published={published} /> : '';
    const imageArea = (mainImage && !previewShowing && version === 'v2') ? (
      <MainImage mainImage={mainImage} onEdit={this.toggleImageManagement} />
    ) : (
      ''
    );
    const imageManagement = imageManagementShowing ? (
      <ImageManagement
        onExit={this.toggleImageManagement}
        mainImage={mainImage}
        version={version}
        onMainImageUrlChange={this.handleMainImageUrlChange}
      />
    ) : (
      ''
    );
    const moreConfig = moreConfigShowing ? (
      <MoreConfig
        onExit={this.toggleMoreConfig}
        passedData={this.state}
        onSaveDraft={this.onSaveDraft}
        onConfigChange={this.handleConfigChange}
      />
    ) : (
      ''
    );
    const orgArea = organization ? (
      <OrgSettings
        organization={organization}
        postUnderOrg={postUnderOrg}
        onToggle={this.toggleOrgPosting}
      />
    ) : (
      ''
    );
    const errorsArea = errors ? <Errors errorsList={errors} /> : '';
    let editorView = '';
    if (previewShowing) {
      editorView = (
        <div>
          {errorsArea}
          {orgArea}
          {imageArea}
          <BodyPreview
            previewResponse={previewResponse}
            articleState={this.state}
            version="article-preview"
          />
        </div>
      );
    } else if (helpShowing) {
      editorView = <BodyPreview previewResponse={{processed_html: helpHTML}} version="help" />;
    } else {
      let controls = '';
      let moreConfigBottomButton = '';
      if (version === 'v2') {
        moreConfigBottomButton = (
          <button
            type='button'
            className="articleform__detailsButton articleform__detailsButton--moreconfig articleform__detailsButton--bottom"
            onClick={this.toggleMoreConfig}
          >
            <img src={ThreeDotsIcon} alt='menu dots' />
          </button>
        )
        controls = (
          <div className={title.length > 128 ? 'articleform__titleTooLong' : ''}>
            <Title defaultValue={title}
              onKeyDown={this.handleTitleKeyDown}
              onChange={linkState(this, 'title')} />
            <div className="articleform__detailfields">
              <Tags defaultValue={tagList} onInput={linkState(this, 'tagList')} />
              <button
                className="articleform__detailsButton articleform__detailsButton--image"
                onClick={this.toggleImageManagement}
              >
                <img src={ImageUploadIcon} />
              </button>
              <button
                className="articleform__detailsButton articleform__detailsButton--moreconfig"
                onClick={this.toggleMoreConfig}
              >
                <img src={ThreeDotsIcon} />
              </button>
            </div>
          </div>
        )
      }
      editorView = (
        <div>
          {errorsArea}
          {orgArea}
          {imageArea}
          {controls}
          <BodyMarkdown
            defaultValue={bodyMarkdown}
            onKeyDown={this.handleBodyKeyDown}
            onChange={linkState(this, 'bodyMarkdown')}
          />
          <button
            className="articleform__detailsButton articleform__detailsButton--image articleform__detailsButton--bottom"
            onClick={this.toggleImageManagement}
          >
            <img src={ImageUploadIcon} alt="upload images" />
            {' '}
IMAGES
          </button>
          {moreConfigBottomButton}
        </div>
      );
    }
    return (
      <form
        className={`articleform__form articleform__form--${version}`}
        onSubmit={this.onSubmit}
        onInput={this.toggleEdit}
      >
        {editorView}
        <PublishToggle
          published={published}
          version={version}
          previewShowing={previewShowing}
          helpShowing={helpShowing}
          onPreview={this.fetchPreview}
          onPublish={this.onPublish}
          onHelp={this.toggleHelp}
          onSaveDraft={this.onSaveDraft}
          onClearChanges={this.onClearChanges}
          edited={this.state.edited}
          onChange={linkState(this, 'published')}
        />
        {notice}
        {imageManagement}
        {moreConfig}
      </form>
    );
  }
}
