import React, { useState } from 'react';
import {
  PaymentElement,
  useStripe,
  useElements
} from '@stripe/react-stripe-js';
import './CheckoutForm.css';

const CheckoutForm = ({ onSuccess, onBack }) => {
  const stripe = useStripe();
  const elements = useElements();

  const [message, setMessage] = useState(null);
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!stripe || !elements) {
      return;
    }

    setIsLoading(true);
    setMessage(null);

    const { error, paymentIntent } = await stripe.confirmPayment({
      elements,
      confirmParams: {
        return_url: window.location.origin + '/payment-success',
      },
      redirect: 'if_required'
    });

    if (error) {
      setMessage(error.message);
      setIsLoading(false);
    } else if (paymentIntent && paymentIntent.status === 'succeeded') {
      onSuccess(paymentIntent.status);
      setIsLoading(false);
    } else {
      setMessage('An unexpected error occurred.');
      setIsLoading(false);
    }
  };

  const paymentElementOptions = {
    layout: 'tabs'
  };

  return (
    <div className="checkout-form-container">
      <form id="payment-form" onSubmit={handleSubmit}>
        <PaymentElement 
          id="payment-element" 
          options={paymentElementOptions}
        />
        
        {message && (
          <div id="payment-message" className="error-message">
            {message}
          </div>
        )}

        <div className="button-group">
          <button 
            type="button" 
            onClick={onBack} 
            className="back-button"
            disabled={isLoading}
          >
            Back
          </button>
          <button 
            disabled={isLoading || !stripe || !elements} 
            id="submit"
            className="submit-button"
          >
            <span id="button-text">
              {isLoading ? (
                <div className="spinner" id="spinner"></div>
              ) : (
                'Pay now'
              )}
            </span>
          </button>
        </div>
      </form>
    </div>
  );
};

export default CheckoutForm;
