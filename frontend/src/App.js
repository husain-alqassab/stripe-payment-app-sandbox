import React, { useState, useEffect } from 'react';
import { loadStripe } from '@stripe/stripe-js';
import { Elements } from '@stripe/react-stripe-js';
import axios from 'axios';
import './App.css';
import ProductList from './components/ProductList';
import CheckoutForm from './components/CheckoutForm';
import PaymentStatus from './components/PaymentStatus';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8080';

function App() {
  const [stripePromise, setStripePromise] = useState(null);
  const [products, setProducts] = useState([]);
  const [selectedProduct, setSelectedProduct] = useState(null);
  const [clientSecret, setClientSecret] = useState('');
  const [paymentIntentId, setPaymentIntentId] = useState('');
  const [paymentStatus, setPaymentStatus] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  // Load Stripe publishable key
  useEffect(() => {
    const fetchConfig = async () => {
      try {
        const { data } = await axios.get(`${API_URL}/api/config`);
        setStripePromise(loadStripe(data.publishableKey));
      } catch (err) {
        console.error('Failed to load Stripe configuration:', err);
        setError('Failed to initialize payment system. Please try again later.');
      }
    };
    fetchConfig();
  }, []);

  // Load products
  useEffect(() => {
    const fetchProducts = async () => {
      try {
        const { data } = await axios.get(`${API_URL}/api/products`);
        setProducts(data.products);
      } catch (err) {
        console.error('Failed to load products:', err);
        setError('Failed to load products. Please refresh the page.');
      }
    };
    fetchProducts();
  }, []);

  const handleProductSelect = async (product) => {
    setSelectedProduct(product);
    setLoading(true);
    setError(null);

    try {
      const { data } = await axios.post(`${API_URL}/api/create-payment-intent`, {
        amount: product.price,
        currency: product.currency,
        description: product.name,
        metadata: {
          productId: product.id,
          productName: product.name
        }
      });

      setClientSecret(data.clientSecret);
      setPaymentIntentId(data.paymentIntentId);
    } catch (err) {
      console.error('Failed to create payment intent:', err);
      setError(err.response?.data?.error || 'Failed to initialize payment. Please try again.');
      setSelectedProduct(null);
    } finally {
      setLoading(false);
    }
  };

  const handlePaymentSuccess = (status) => {
    setPaymentStatus(status);
    setSelectedProduct(null);
    setClientSecret('');
  };

  const handleBack = () => {
    setSelectedProduct(null);
    setClientSecret('');
    setError(null);
  };

  const handleNewPurchase = () => {
    setPaymentStatus(null);
    setPaymentIntentId('');
  };

  const appearance = {
    theme: 'stripe',
    variables: {
      colorPrimary: '#0570de',
      colorBackground: '#ffffff',
      colorText: '#30313d',
      colorDanger: '#df1b41',
      fontFamily: 'Ideal Sans, system-ui, sans-serif',
      spacingUnit: '4px',
      borderRadius: '8px',
    }
  };

  const options = {
    clientSecret,
    appearance,
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>Secure Payment Portal</h1>
        <p>Powered by Stripe</p>
      </header>

      <main className="App-main">
        {error && (
          <div className="error-message">
            <p>{error}</p>
            <button onClick={() => setError(null)}>Dismiss</button>
          </div>
        )}

        {paymentStatus ? (
          <PaymentStatus 
            status={paymentStatus} 
            paymentIntentId={paymentIntentId}
            onNewPurchase={handleNewPurchase}
          />
        ) : !selectedProduct ? (
          <ProductList 
            products={products} 
            onSelectProduct={handleProductSelect}
            loading={loading}
          />
        ) : clientSecret && stripePromise ? (
          <div className="checkout-container">
            <div className="product-summary">
              <h2>Complete Your Purchase</h2>
              <div className="selected-product">
                <h3>{selectedProduct.name}</h3>
                <p>{selectedProduct.description}</p>
                <p className="price">
                  ${(selectedProduct.price / 100).toFixed(2)} {selectedProduct.currency.toUpperCase()}
                </p>
              </div>
            </div>
            <Elements options={options} stripe={stripePromise}>
              <CheckoutForm 
                onSuccess={handlePaymentSuccess}
                onBack={handleBack}
              />
            </Elements>
          </div>
        ) : (
          <div className="loading">
            <div className="spinner"></div>
            <p>Initializing secure payment...</p>
          </div>
        )}
      </main>

      <footer className="App-footer">
        <p>All payments are processed securely through Stripe</p>
        <p className="disclaimer">Test mode • Use card: 4242 4242 4242 4242</p>
      </footer>
    </div>
  );
}

export default App;
