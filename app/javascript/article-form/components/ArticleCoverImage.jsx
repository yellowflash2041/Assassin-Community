import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { generateMainImage } from '../actions';
import { validateFileInputs } from '../../packs/validateFileInputs';
import { Button } from '@crayons';
import { Spinner } from '@crayons/Spinner/Spinner';

export class ArticleCoverImage extends Component {
  state = {
    uploadError: false,
    uploadErrorMessage: null,
    uploadingImage: false,
  };

  onImageUploadSuccess = (...args) => {
    this.props.onMainImageUrlChange(...args);
    this.setState({ uploadingImage: false });
  };

  handleMainImageUpload = (e) => {
    e.preventDefault();

    this.setState({ uploadingImage: true });
    this.clearUploadError();

    if (validateFileInputs()) {
      const payload = { image: e.target.files, wrap_cloudinary: true };

      generateMainImage(payload, this.onImageUploadSuccess, this.onUploadError);
    }
  };

  clearUploadError = () => {
    this.setState({
      uploadError: false,
      uploadErrorMessage: null,
    });
  };

  onUploadError = (error) => {
    this.setState({
      uploadingImage: false,
      uploadError: true,
      uploadErrorMessage: error.message,
    });
  };

  triggerMainImageRemoval = (e) => {
    e.preventDefault();
    const { onMainImageUrlChange } = this.props;
    onMainImageUrlChange({
      links: [],
    });
  };

  render() {
    const { mainImage } = this.props;
    const { uploadError, uploadErrorMessage, uploadingImage } = this.state;
    const uploadLabel = mainImage ? 'Change' : 'Add a cover image';

    return (
      <div className="crayons-article-form__cover" role="presentation">
        {!uploadingImage && mainImage && (
          <img
            src={mainImage}
            className="crayons-article-form__cover__image"
            width="250"
            height="105"
            alt="Post cover"
          />
        )}
        <div className="flex items-center">
          {uploadingImage ? (
            <span class="lh-base pl-1 border-0 py-2 inline-block">
              <Spinner /> Uploading...
            </span>
          ) : (
            <>
              <Button variant="outlined" className="mr-2 whitespace-nowrap">
                <label htmlFor="cover-image-input">{uploadLabel}</label>
                <input
                  id="cover-image-input"
                  type="file"
                  onChange={this.handleMainImageUpload}
                  accept="image/*"
                  className="w-100 h-100 absolute left-0 right-0 top-0 bottom-0 overflow-hidden opacity-0 cursor-pointer"
                  data-max-file-size-mb="25"
                />
              </Button>
              {mainImage && (
                <Button
                  variant="ghost-danger"
                  onClick={this.triggerMainImageRemoval}
                >
                  Remove
                </Button>
              )}
            </>
          )}
        </div>
        {uploadError && (
          <p className="articleform__uploaderror">{uploadErrorMessage}</p>
        )}
      </div>
    );
  }
}

ArticleCoverImage.propTypes = {
  mainImage: PropTypes.string.isRequired,
  onMainImageUrlChange: PropTypes.func.isRequired,
};

ArticleCoverImage.displayName = 'ArticleCoverImage';
