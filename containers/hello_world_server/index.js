const express = require('express');
const app = express();
//const message = require('./hello_world.json')
const PORT = 4000;

app.use(express.json());

app.get('/', (req ,res) => {
   res.status(200).json({ "id": "1", "message": "Hello world"})
})


app.listen(PORT, () => {
  console.log(`helloworld: listening on port ${PORT}`);
});