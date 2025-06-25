const express = require('express');
const axios = require('axios');
const app = express();
const PORT = 3000;


const SOURCE_URL = 'http://hello-world:4000/';

//const SOURCE_URL = 'http://localhost:4000/';
// const SOURCE_URL = process.env.SOURCE_URL || 'http://localhost:4000/';

app.use(express.json());

async function reverseMessage (req, res) {
  try {
    const response = await axios.get(SOURCE_URL);
    const originalMessage = response.data;

    const reversedMessage = originalMessage.message.split('').reverse().join('');
    res.status(200).json({ id: originalMessage.id, message: reversedMessage });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch and reverse message' });
  }

}

app.get('/', reverseMessage);

app.listen(PORT, () => {
  console.log(`Reverse helloworld: listening on port ${PORT}`);
});