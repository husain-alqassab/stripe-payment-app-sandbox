import React from 'react';
import './ProductList.css';

const ProductList = ({ products, onSelectProduct, loading }) => {
  return (
    <div className="product-list">
      <h2>Choose Your Plan</h2>
      <div className="products-grid">
        {products.map((product) => (
          <div key={product.id} className="product-card">
            <div className="product-header">
              <h3>{product.name}</h3>
            </div>
            <div className="product-body">
              <p className="product-description">{product.description}</p>
              <div className="product-price">
                <span className="currency">$</span>
                <span className="amount">{(product.price / 100).toFixed(2)}</span>
                <span className="period">/{product.currency.toUpperCase()}</span>
              </div>
            </div>
            <div className="product-footer">
              <button
                className="select-button"
                onClick={() => onSelectProduct(product)}
                disabled={loading}
              >
                {loading ? 'Processing...' : 'Select Plan'}
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default ProductList;
