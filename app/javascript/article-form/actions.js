export function previewArticle(payload, successCb, failureCb) {
  fetch('/articles/preview', {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      article_body: payload,
    }),
    credentials: 'same-origin',
  })
    .then((response) => response.json())
    .then(successCb)
    .catch(failureCb);
}

export function getArticle() {}

function processPayload(payload) {
  const {
    /* eslint-disable no-unused-vars */
    previewShowing,
    helpShowing,
    previewResponse,
    helpHTML,
    imageManagementShowing,
    moreConfigShowing,
    errors,
    /* eslint-enable no-unused-vars */
    ...neededPayload
  } = payload;
  return neededPayload;
}

export function submitArticle(payload, clearStorage, errorCb, failureCb) {
  const method = payload.id ? 'PUT' : 'POST';
  const url = payload.id ? `/articles/${payload.id}` : '/articles';
  fetch(url, {
    method,
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      article: processPayload(payload),
    }),
    credentials: 'same-origin',
  })
    .then((response) => response.json())
    .then((response) => {
      if (response.current_state_path) {
        clearStorage();
        window.location.replace(response.current_state_path);
      } else {
        // If there is an error and the method is POST, we know they are trying to publish.
        errorCb(response, method === 'POST');
      }
    })
    .catch(failureCb);
}

function generateUploadFormdata(payload) {
  const token = window.csrfToken;
  const formData = new FormData();
  formData.append('authenticity_token', token);

  Object.entries(payload.image).forEach(([_, value]) =>
    formData.append('image[]', value),
  );

  if (payload.wrap_cloudinary) {
    formData.append('wrap_cloudinary', 'true');
  }
  return formData;
}

export function generateMainImage(payload, successCb, failureCb) {
  fetch('/image_uploads', {
    method: 'POST',
    headers: {
      'X-CSRF-Token': window.csrfToken,
    },
    body: generateUploadFormdata(payload),
    credentials: 'same-origin',
  })
    .then((response) => response.json())
    .then((json) => {
      if (json.error) {
        throw new Error(json.error);
      }

      return successCb(json);
    })
    .catch(failureCb);
}
