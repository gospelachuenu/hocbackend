require('dotenv').config();
const express = require('express');
const cors = require('cors');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Create a payment intent
app.post('/create-payment-intent', async (req, res) => {
  try {
    const { amount, currency, description } = req.body;

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount, // amount in cents
      currency: currency,
      description: description,
      automatic_payment_methods: {
        enabled: true,
      },
    });

    res.json({
      clientSecret: paymentIntent.client_secret,
    });
  } catch (error) {
    console.error('Error creating payment intent:', error);
    res.status(500).json({ error: error.message });
  }
});

// Save transaction
app.post('/save-transaction', async (req, res) => {
  try {
    const { paymentMethod, amount, currency, status, userId, timestamp } = req.body;
    
    // Here you would typically save the transaction to your database
    // For now, we'll just log it
    console.log('Transaction saved:', {
      paymentMethod,
      amount,
      currency,
      status,
      userId,
      timestamp,
    });

    res.json({ success: true });
  } catch (error) {
    console.error('Error saving transaction:', error);
    res.status(500).json({ error: error.message });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
}); 