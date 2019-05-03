import PropTypes from 'prop-types';
import { h, Component } from 'preact';

class Categories extends Component {
  options = () => {
    const { categoriesForSelect } = this.props
    return categoriesForSelect.map(array => {
      return(
        <option value={array[1]}>{array[0]}</option>
      )
    })
  }

  details = () => {
    const { categoriesForDetails } = this.props
    const rules = categoriesForDetails.map(category => {
      const paragraphText = `${category.name}: ${category.rules}`
      return(
        <p>
          {paragraphText}
        </p>
      )
    })

    return(
      <details>
        <summary>
          Category details/rules
        </summary>
        {rules}
      </details>
    )
  }

  render() {
    return(
      <div className="field">
        <label className="listingform__label" htmlFor="category">
          Category
        </label>
        <select className="listingform__input" name="classified_listing[category]">
          {this.options()}
        </select>
        {this.details()}
      </div>
    )
  }
}

Categories.propTypes = {
  categoriesForSelect: PropTypes.array.isRequired,
  categoriesForDetails: PropTypes.array.isRequired,
}


export default Categories;