import React from 'react';
import './PaymentStatus.css';

const PaymentStatus = ({ status, paymentIntentId, onNewPurchase }) => {
  const isSuccess = status === 'succeeded';

  return (
    <div className="payment-status">
      <div className={`status-container ${isSuccess ? 'success' : 'failed'}`}>
        <div className="status-icon">
          {isSuccess ? (
            <svg width="64" height="64" viewBox="0 0 64 64" fill="none">
              <circle cx="32" cy="32" r="32" fill="#10B981"/>
              <path d="M20 32L28 40L44 24" stroke="white" strokeWidth="4" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          ) : (
            <svg width="64" height="64" viewBox="0 0 64 64" fill="none">
              <circle cx="32" cy="32" r="32" fill="#EF4444"/>
              <path d="M24 24L40 40M40 24L24 40" stroke="white" strokeWidth="4" strokeLinecap="round"/>
            </svg>
          )}
        </div>
        
        <h2>{isSuccess ? 'Payment Successful!' : 'Payment Failed'}</h2>
        
        <p className="status-message">
          {isSuccess 
            ? 'Thank you for your purchase. Your payment has been processed successfully.'
            : 'We were unable to process your payment. Please try again or contact support.'
          }
        </p>

        {paymentIntentId && (
          <div className="payment-details">
            <p className="transaction-id">
              Transaction ID: <code>{paymentIntentId}</code>
            </p>
          </div>
        )}

        <div className="status-actions">
          <button 
            className="new-purchase-button"
            onClick={onNewPurchase}
          >
            {isSuccess ? 'Make Another Purchase' : 'Try Again'}
          </button>
        </div>

        {isSuccess && (
          <div className="next-steps">
            <h3>What's Next?</h3>
            <ul>
              <li>You will receive a confirmation email shortly</li>
              <li>Your access will be activated within a few minutes</li>
              <li>Keep your transaction ID for reference</li>
            </ul>
          </div>
        )}
      </div>
    </div>
  );
};

export default PaymentStatus;
